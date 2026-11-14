"""Execute one case in ZEsarUX and collect its ZXHost outputs."""

import json
import os
import re
import select
import sys
import time
from contextlib import ExitStack
from pathlib import Path

from tools.zesarux.runner import default_emulator
from tools.zesarux.tap_runner import send_key_script

from .audio import check_audio_expectations, preserve_partial_audio, write_audio_wav
from .comparison import format_hex, output_basename, output_prefix
from .support import FrameworkError, console_label, interactive_console, step_prefix
from .zx_host.session import ZXHostSession


def step_name(log):
    for line in log.splitlines():
        if line.strip():
            return line.strip()
    return "step"


def completion_failure_detail(log):
    lines = [line.strip() for line in log.splitlines()
             if line.strip() and line.strip() not in ("PASS", "FAIL:")]
    assertions = [line for line in lines if line.startswith("line=")]
    messages = [line for line in lines if not line.startswith("line=")]
    parts = []
    if messages:
        parts.append("[" + " ".join(messages) + "]")
    parts.extend(assertions)
    return lines, " ".join(parts)


DATA_RE = re.compile(r"^DATA\s+(\d+)\s+(\d+)\s+(\d+)\s*$", re.MULTILINE)
STEP_BEGIN = 0x08  # RESULT2 flag for a named step awaiting host acknowledgement.


def find_zesarux(explicit):
    if explicit:
        return explicit
    return default_emulator()


def open_uart_bridge(resources):
    if not hasattr(os, "openpty"):
        raise FrameworkError("UART steps require a POSIX pseudoterminal")
    import tty

    master, slave = os.openpty()
    resources.callback(os.close, master)
    resources.callback(os.close, slave)
    tty.setraw(slave)
    os.set_blocking(master, False)
    return master, os.ttyname(slave)


def run_uart_step(master, action):
    if "expect" in action:
        expected = bytes(action["expect"])
        received = bytearray()
        deadline = time.monotonic() + 1.0
        while len(received) <= len(expected):
            wait = max(0, deadline - time.monotonic()) if len(received) < len(expected) else 0
            if not select.select([master], [], [], wait)[0]:
                break
            chunk = os.read(master, len(expected) + 1 - len(received))
            if not chunk:
                break
            received.extend(chunk)
        if received != expected:
            return (f"UART TX expected [{expected.hex(' ')}], "
                    f"received [{received.hex(' ')}]")
    if "send" in action:
        payload = bytes(action["send"])
        count = os.write(master, payload)
        if count != len(payload):
            return f"UART RX wrote {count} of {len(payload)} host bytes"
    return None


def check_tsconf_sysconfig(remote, value):
    checks = (
        ("tsconf-get-af-port 32", f"{value:02X}H", "SysConfig"),
        ("tsconf-get-af-port 43", "0FH" if value & 4 else "00H", "CacheConfig"),
        ("get-cpu-turbo-speed", str(1 << (value & 3)), "CPU turbo factor"),
    )
    for command, expected, name in checks:
        actual = remote.command(command).strip().partition("\n")[0].strip()
        if actual != expected:
            return f"{name} expected {expected}, got {actual!r}"
    return None


def check_tsconf_registers(remote, registers):
    for register, value in registers.items():
        index = int(register, 16)
        actual = remote.command(f"tsconf-get-af-port {index}").strip().partition("\n")[0].strip()
        expected = f"{value:02X}H"
        if actual != expected:
            return f"TSConf register {index:02X} expected {expected}, got {actual!r}"
    return None


def _run_session_once(manifest_path, case_name, profile_name, zesarux, port, timeout, output_dir,
                      verbose=False, audio_capture=False, audio_expectations=None,
                      audio_step_flush_cycles=0, emulator_steps=None,
                      uart_bridge=None):
    output_dir.mkdir(parents=True, exist_ok=True)
    audio_raw_path = output_dir / f"{case_name}.rwa" if audio_capture else None
    extra_args = ["--hardware-debug-ports", "--realvideo"]
    if emulator_steps:
        extra_args.extend(("--frameskip", "0", "--disable-autoframeskip"))
    if uart_bridge:
        extra_args.extend(("--uartbridge-file", uart_bridge[1]))
    manifest_path = Path(manifest_path)
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    extra_args.extend(manifest.get("emulator_args", []))
    if manifest.get("romfile"):
        extra_args.extend(("--romfile", manifest["romfile"]))
    emulator_images = manifest.get("emulator_images", {})
    for device in ("mmc", "ide", "trd"):
        filename = emulator_images.get(device)
        if filename:
            image = (manifest_path.parent / filename).resolve()
            extra_args.extend((f"--{device}-file", str(image), f"--enable-{device}",
                               f"--{device}-no-persistent-writes"))
    if audio_capture:
        audio_raw_path.unlink(missing_ok=True)
        extra_args.extend(("--enableaudiodac", "--audiodactype", "Covox Pentagon",
                           "--aofile", str(audio_raw_path)))
    session = ZXHostSession(
        str(manifest_path),
        zesarux,
        machine=manifest["machine"],
        port=port,
        video_output="null",
        audio_output="null",
        extra_args=tuple(extra_args),
        log_path=str(output_dir / f"{output_prefix(case_name, profile_name)}zesarux.log"),
        quickexit=True,
    )
    shots = []
    data_outputs = []
    data_errors = []
    step_errors = []
    steps = []
    audio_checkpoints = []
    status = 0
    skips = 0
    live_steps = interactive_console(sys.stdout)
    open_step = None
    completion_detail = []
    completion_failure_inline = False
    audio_step_names = list((audio_expectations or {}).get("steps", {}))
    active_step = 0
    active_step_name = audio_step_names[0] if audio_step_names else "step"
    session_completed = False
    try:
        session.start(command=0)
        while True:
            result = session.wait_for_completion(timeout=timeout)
            values = result["results"]
            status, step, flags = values[0], values[1], values[2]
            log = result["log"]
            state = result["state"]
            done_with_more = (
                state == manifest["protocol"]["states"]["done"] and flags & 0x02
            )
            if done_with_more and flags & STEP_BEGIN:
                if open_step is not None:
                    raise RuntimeError("target started a second step before completing the current step")
                active_step, active_step_name = step, step_name(log)
                open_step = (active_step, active_step_name)
                if live_steps:
                    print(f"{step_prefix(step + 1)}{active_step_name} ", end="", flush=True)
                session.submit(command=0)
                continue
            if (state != manifest["protocol"]["states"]["idle"] and
                    not done_with_more):
                completion_suffix = ""
                if status == 1:
                    completion_detail, completion_suffix = completion_failure_detail(log)
                if open_step is not None:
                    if status == 0:
                        raise RuntimeError("target finished with a step still open")
                    final_status = "SKIP" if status == 2 else "FAIL"
                    completion_failure_inline = bool(completion_suffix)
                    prefix = "" if live_steps else f"{step_prefix(open_step[0] + 1)}{open_step[1]} "
                    suffix = f" {completion_suffix}" if completion_failure_inline else ""
                    print(f"{prefix}{console_label(final_status)}{suffix}", flush=True)
                    open_step = None
                break
            if open_step is None:
                name = step_name(log)
            else:
                started_step, name = open_step
                if step != started_step:
                    raise RuntimeError(f"target reported step {step + 1} while step {started_step + 1} is open")
                log = f"{name}\n{log}"
            active_step = step
            active_step_name = name
            step_status = {0: "PASS", 1: "FAIL", 2: "SKIP"}.get(status, str(status))
            action = (emulator_steps or {}).get(name, {})
            step_error = None
            if status == 0:
                if "uart" in action:
                    step_error = run_uart_step(uart_bridge[0], action["uart"])
                if step_error is None and "tsconf_sysconfig" in action:
                    step_error = check_tsconf_sysconfig(session.remote, action["tsconf_sysconfig"])
                if step_error is None and "tsconf_registers" in action:
                    step_error = check_tsconf_registers(session.remote, action["tsconf_registers"])
            if step_error:
                step_status = "FAIL"
                step_errors.append(f"step {step + 1} {name}: {step_error}")
            if live_steps and open_step is not None:
                print(console_label(step_status), flush=True)
            else:
                print(f"{step_prefix(step + 1)}{name} {console_label(step_status)}", flush=True)
            open_step = None
            shot_after_resume = action.get("shot", False)
            shot = bool(flags & 0x01) or shot_after_resume
            more = bool(flags & 0x02)
            path = None
            if shot and not shot_after_resume:
                session.run_cycles(200_000)
                path = output_dir / output_basename(case_name, profile_name, step, name, ".png")
                session.capture(str(path))
                shots.append((step, name, path))
            if flags & 0x04:
                match = DATA_RE.search(log)
                if not match:
                    data_errors.append(f"step {step} {name}: DATA flag without a DATA line")
                else:
                    address, length, kind = (int(value) for value in match.groups())
                    if length == 0:
                        data_errors.append(f"step {step} {name}: empty data payload")
                    else:
                        raw = session.remote.read_memory(address, length)
                        if len(raw) != length:
                            data_errors.append(
                                f"step {step} {name}: read {len(raw)} of {length} data bytes at 0x{address:04X}")
                        else:
                            if kind == 0:
                                content = format_hex(raw).encode("ascii")
                                extension = ".txt"
                            elif kind == 1:
                                content = raw
                                extension = ".txt"
                            elif kind == 3:
                                content = raw.split(b"\0", 1)[0]
                                extension = ".toml"
                            else:
                                content = raw
                                extension = ".bin"
                            data_path = (output_dir / output_basename(
                                case_name, profile_name, step, name, extension))
                            data_path.write_bytes(content)
                            data_outputs.append((step, name, data_path, kind))
                            if verbose:
                                print(f"      data {kind} {length}B -> {data_path.name}")
            if audio_capture:
                if audio_step_flush_cycles:
                    session.run_cycles(audio_step_flush_cycles)
                audio_checkpoints.append({
                    "step": step,
                    "name": name,
                    "end_offset": audio_raw_path.stat().st_size,
                })
            if status == 2:
                skips += 1
            steps.append({"step": step, "name": name, "status": 1 if step_error else status,
                          "shot": shot, "more": more, "log": log})
            if verbose:
                if log:
                    for line in log.splitlines()[1:]:
                        if line.strip():
                            print(f"      {line}")
            if not more:
                break
            active_step = step + 1
            active_step_name = (audio_step_names[active_step]
                                if active_step < len(audio_step_names)
                                else f"step{active_step}")
            session.submit(command=0)
            if action.keys() - {"uart", "tsconf_sysconfig", "tsconf_registers"}:
                if action.get("nmi"):
                    session.remote.command("generate-nmi")
                if "joystick" in action:
                    session.remote.command(f"set-ui-io-ports {'ff' * 8}{action['joystick']:02x}")
                session.run_cycles(action.get("settle", 200_000))
                if action.get("before_shot_keys"):
                    send_key_script(session.remote, action["before_shot_keys"], 100_000, 100_000)
                if shot_after_resume:
                    session.run_cycles(200_000)
                    path = output_dir / output_basename(case_name, profile_name, step, name, ".png")
                    session.capture(str(path))
                    shots.append((step, name, path))
                if action.get("keys"):
                    send_key_script(session.remote, action["keys"], 100_000, 100_000)
        session.exit_cpu_step()
        if audio_capture:
            session.shutdown()
        session_completed = True
    except Exception as error:
        if open_step is not None:
            step, name = open_step
            prefix = "" if live_steps else f"{step_prefix(step + 1)}{name} "
            print(f"{prefix}{console_label('FAIL')}", flush=True)
            if isinstance(error, TimeoutError) and "ZXHost did not complete" in str(error):
                raise TimeoutError(f"step {step + 1} {name!r}: {error}") from error
        elif steps and isinstance(error, TimeoutError) and "ZXHost did not complete" in str(error):
            last = steps[-1]
            raise TimeoutError(f"after step {last['step'] + 1} {last['name']!r}: {error}") from error
        raise
    finally:
        session.close()
        if audio_capture and not session_completed:
            try:
                preserve_partial_audio(audio_raw_path, output_dir, case_name, profile_name,
                                       audio_checkpoints, active_step, active_step_name)
            except Exception as audio_error:
                print(f"      audio capture could not be split: {audio_error}", flush=True)
    audio_errors = []
    audio_outputs = []
    if audio_capture:
        if not audio_raw_path.is_file():
            audio_errors.append("ZEsarUX did not create the raw audio capture")
        else:
            raw_audio = audio_raw_path.read_bytes()
            expectations_by_step = (audio_expectations or {}).get("steps", {})
            start_offset = 0
            for checkpoint in audio_checkpoints:
                end_offset = min(checkpoint["end_offset"], len(raw_audio))
                segment = raw_audio[start_offset:end_offset]
                start_offset = end_offset
                step_expectations = expectations_by_step.get(checkpoint["name"])
                if step_expectations and len(segment) < 2048:
                    audio_errors.append(
                        f"step {checkpoint['step'] + 1} {checkpoint['name']}: "
                        f"audio segment is too short ({len(segment)} bytes)")
                elif step_expectations:
                    error = check_audio_expectations(segment, {
                        **step_expectations,
                        "minimum_level_samples": (audio_expectations or {}).get(
                            "minimum_level_samples", 1),
                    })
                    if error:
                        audio_errors.append(f"step {checkpoint['step'] + 1} {checkpoint['name']}: {error}")
                audio_path = output_dir / output_basename(
                    case_name, profile_name, checkpoint["step"], checkpoint["name"], ".wav")
                write_audio_wav(segment, audio_path)
                audio_outputs.append((checkpoint["step"], checkpoint["name"], audio_path))
                if verbose:
                    print(f"      audio -> {audio_path.name}")
            audio_raw_path.unlink(missing_ok=True)
    return {"steps": steps, "shots": shots, "data": data_outputs,
            "data_errors": data_errors, "step_errors": step_errors, "status": status, "skips": skips,
            "completion_detail": completion_detail,
            "completion_failure_inline": completion_failure_inline,
            "audio_outputs": audio_outputs, "audio_errors": audio_errors}


def run_session(manifest_path, case_name, profile_name, zesarux, port, timeout, output_dir,
                verbose=False, audio_capture=False, audio_expectations=None,
                audio_step_flush_cycles=0, emulator_steps=None):
    """Run one case, retrying only emulator transport failures.

    ZEsarUX occasionally needs a moment before its remote port can be bound
    again after the previous process exits; a real target timeout is reported
    without retrying.
    """
    last_error = None
    for attempt in range(3):
        try:
            with ExitStack() as resources:
                uart_bridge = None
                if any("uart" in action for action in (emulator_steps or {}).values()):
                    uart_bridge = open_uart_bridge(resources)
                return _run_session_once(manifest_path, case_name, profile_name,
                                         zesarux, port, timeout, output_dir, verbose, audio_capture,
                                         audio_expectations, audio_step_flush_cycles,
                                         emulator_steps, uart_bridge)
        except TimeoutError as error:
            if "ZXHost did not complete" in str(error):
                raise
            last_error = error
        except OSError as error:
            last_error = error
        if attempt < 2:
            time.sleep(1.0)
    raise last_error
