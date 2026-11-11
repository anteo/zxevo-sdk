"""Build and run ZX Evolution test suites using ZEsarUX and ZXHost."""

from __future__ import annotations

import argparse
import copy
import difflib
import hashlib
import json
import os
import re
import select
import shutil
import signal
import struct
import subprocess
import sys
import time
import wave
import zlib
from contextlib import ExitStack
from dataclasses import dataclass
from pathlib import Path

from tools.zesarux.runner import default_emulator
from tools.zesarux.tap_runner import send_key_script

from .zx_host.session import ZXHostSession

TEST_RUNNER = Path(__file__).resolve().parent
ROOT = TEST_RUNNER.parents[1]
TEST_SUPPORT = ROOT / "lib" / "test_support"
PROTOCOL_FILE = TEST_SUPPORT / "protocol.json"
TEST_SUPPORT_INCLUDE = TEST_SUPPORT / "include"
ZX_HOST_SOURCE = TEST_SUPPORT / "src" / "zx_host.c"
ZXTEST_SOURCE = TEST_SUPPORT / "src" / "zx_test.c"
ZCC = os.environ.get("ZCC", "zcc")
PAGE_SIZE = 0x4000

# zcc converts its compiler child's exit status to 1. The shell still
# identifies the crashed executable in stderr, including under make.
SDCC_SIGSEGV = re.compile(
    r"^(?:[^:\n]+: )?(?:line \d+: )?(?:\d+\s+)?Segmentation fault"
    r"(?:: 11| \(core dumped\))?\s+[^\n]*\bz88dk-zsdcc\b",
    re.MULTILINE,
)


def run_test_build(command, *, crash_log, env=None):
    """Retry one compiler crash and preserve the first attempt's diagnostics."""
    result = subprocess.run(command, capture_output=True, text=True, env=env)
    if not result.returncode or not (
            result.returncode == -signal.SIGSEGV or SDCC_SIGSEGV.search(result.stderr)):
        return result

    crash_log.parent.mkdir(parents=True, exist_ok=True)
    crash_log.write_text(result.stdout + result.stderr, encoding="utf-8")
    print(f"\n  RETRY 2/2: compiler SIGSEGV, see {crash_log}", flush=True)
    return subprocess.run(command, capture_output=True, text=True, env=env)


@dataclass(frozen=True)
class TargetBuild:
    """Configuration-specific arguments, environment, sources and cache inputs."""

    flags: list[str]
    env: dict[str, str]
    sources: tuple[Path, ...]
    inputs: tuple[Path, ...]


LABEL_COLORS = {
    "BUILD": "1;36",
    "BUILD FAIL": "1;31",
    "RUN": "1;35",
    "PASS": "1;32",
    "FAIL": "1;31",
    "SKIP": "1;33",
    "error": "1;31",
}


def interactive_console(stream):
    return stream.isatty() and os.environ.get("TERM") != "dumb"


def console_label(label, width=0, *, stream=None):
    if stream is None:
        stream = sys.stdout
    padded_label = label.ljust(width)
    color = LABEL_COLORS.get(label)
    if color and interactive_console(stream) and not os.environ.get("NO_COLOR"):
        return f"\033[{color}m{padded_label}\033[0m"
    return padded_label


def step_prefix(number):
    return f"  STEP {number}: "


class FrameworkError(RuntimeError):
    """A build or infrastructure failure, not a test failure."""


class TestFailure(RuntimeError):
    """A test failed in the target or in the golden comparison."""

PROFILE_LIST_KEYS = {"cflags", "defines", "make_args", "make_targets", "extra_libs"}


def merge_profile_layer(target, layer):
    for key, value in layer.items():
        if key == "description":
            continue
        if isinstance(value, dict):
            nested = target.setdefault(key, {})
            if not isinstance(nested, dict):
                raise FrameworkError(f"cannot merge profile field {key!r}: expected an object")
            merge_profile_layer(nested, value)
        elif key in PROFILE_LIST_KEYS and isinstance(value, list):
            current = target.setdefault(key, [])
            if not isinstance(current, list):
                raise FrameworkError(f"cannot merge profile field {key!r}: expected a list")
            for item in value:
                if item not in current:
                    current.append(item)
        else:
            target[key] = copy.deepcopy(value)


def profile_assignment(key, option):
    if key == "make_args":
        match = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)=(.*)$", option)
        return ("make", match.group(1), match.group(2)) if match else None
    if key == "defines":
        match = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)(?:=(.*))?$", option)
        return ("define", match.group(1), match.group(2) or "1") if match else None
    if key == "cflags":
        match = re.match(r"^-pragma-define:([^=]+)=(.*)$", option)
        if match:
            return ("pragma", match.group(1), match.group(2))
        match = re.match(r"^-D([^=]+)(?:=(.*))?$", option)
        if match:
            return ("define", match.group(1), match.group(2) or "1")
    return None


def validate_profile_options(profile):
    assignments = {}
    for key in ("cflags", "defines"):
        for option in profile.get(key, []):
            assignment = profile_assignment(key, option)
            if assignment:
                namespace, name, value = assignment
                identity = (namespace, name)
                previous = assignments.get(identity)
                if previous is not None and previous != value:
                    raise FrameworkError(
                        f"conflicting profile settings for {name}: {previous!r} and {value!r}"
                    )
                assignments[identity] = value
    for option in profile.get("library", {}).get("make_args", []):
        assignment = profile_assignment("make_args", option)
        if assignment:
            namespace, name, value = assignment
            identity = (namespace, name)
            previous = assignments.get(identity)
            if previous is not None and previous != value:
                raise FrameworkError(
                    f"conflicting profile settings for {name}: {previous!r} and {value!r}"
                )
            assignments[identity] = value


def resolve_profiles(profiles, names):
    known = set(profiles) - {"default"}
    unknown = [name for name in names if name not in known]
    if unknown:
        raise FrameworkError(
            f"unknown profile layer(s) {', '.join(repr(name) for name in unknown)}; "
            f"known: {', '.join(sorted(known))}"
        )
    profile = copy.deepcopy(profiles.get("default", {}))
    descriptions = []
    for name in names:
        layer = profiles[name]
        if layer.get("description"):
            descriptions.append(layer["description"])
        merge_profile_layer(profile, layer)
    validate_profile_options(profile)
    profile["name"] = "+".join(names) if names else "default"
    profile["description"] = " / ".join(descriptions)
    return profile


def case_profiles(meta, profiles, selected_profiles):
    names = meta.get("profiles", [])
    if names is None:
        names = []
    if not isinstance(names, list):
        raise FrameworkError("case profiles must be a list of profile layers")
    if any(not isinstance(name, str) for name in names):
        raise FrameworkError("case profile layers must be strings")
    if len(names) != len(set(names)):
        raise FrameworkError("case profile layers must not contain duplicates")
    if selected_profiles:
        unknown = selected_profiles - (set(profiles) - {"default"})
        if unknown:
            raise FrameworkError(
                f"unknown profile layer(s) {', '.join(sorted(unknown))}; "
                f"known: {', '.join(sorted(set(profiles) - {'default'}))}"
            )
        if not (selected_profiles & set(names)):
            return []
    return [resolve_profiles(profiles, names)]

def layout_values(layout):
    values = {
        "code_org": int(layout["code_org"]),
        "data_org": int(layout["data_org"]),
        "bss_org": int(layout["bss_org"]),
        "stack_org": int(layout["stack_org"]),
        "code_page": int(layout["code_page"]),
        "code_window": int(layout.get("code_window", 0)),
        "data_page": int(layout["data_page"]),
    }
    if not 0 <= values["code_window"] <= 3:
        raise FrameworkError("profile layout.code_window must be in 0..3")
    return values


def file_digest(path):
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for block in iter(lambda: stream.read(65536), b""):
            digest.update(block)
    return digest.hexdigest()


def parse_map(path):
    symbols = {}
    pattern = re.compile(r"^(\S+)\s+= \$([0-9A-Fa-f]+)")
    with open(path, "r", encoding="utf-8", errors="replace") as stream:
        for line in stream:
            match = pattern.match(line)
            if match:
                symbols[match.group(1)] = int(match.group(2), 16)
    return symbols


def map_symbol(symbols, name):
    if name not in symbols:
        raise FrameworkError(f"map has no {name} symbol")
    return symbols[name]


def generate_vectors(path):
    data = bytearray(256)
    for address in (0x08, 0x10, 0x18, 0x20, 0x28, 0x30):
        data[address] = 0xC9  # RET
    data[0x38] = 0xED  # RETI
    data[0x39] = 0x4D
    data[0x66] = 0xED  # RETN
    data[0x67] = 0x45
    with open(path, "wb") as stream:
        stream.write(data)

class TestSession(ZXHostSession):
    """ZXHost session with one request per test step."""

    def next_step(self):
        self.sequence = (self.sequence + 1) & 0xFF
        self.protocol.prepare_request(self.remote, 0, (0, 0), self.sequence)

    def shutdown(self):
        self.runner.shutdown()
        self.remote = None


def slug(value, limit=40):
    value = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return (value or "out")[:limit]


def output_prefix(case_name, profile_name=None):
    return f"{case_name}."


def output_basename(case_name, profile_name, step, name, extension):
    """Expected and actual file name; expected lives next to the case."""
    tag = slug(name if name and name != "out" else "out")
    index = step + 1
    return f"{output_prefix(case_name, profile_name)}{index:02d}_{tag}{extension}"


def expected_pattern(case_name, profile_name=None):
    return re.compile(rf"^{re.escape(case_name)}\.\d+_[^/]*\.(?:png|txt|bin)$")


def expected_files(case_path, profile_name):
    case_name = case_path.stem
    pattern = expected_pattern(case_name, profile_name)
    if not case_path.parent.is_dir():
        return []
    return sorted(path for path in case_path.parent.iterdir()
                  if path.is_file() and pattern.match(path.name))


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


def format_hex(raw):
    """Canonical, reviewable hex dump used for the data channel."""
    lines = []
    for offset in range(0, len(raw), 16):
        chunk = raw[offset:offset + 16]
        lines.append(f"{offset:04X}: " + " ".join(f"{byte:02X}" for byte in chunk))
    return "\n".join(lines) + "\n"


def find_zesarux(explicit):
    if explicit:
        return explicit
    return default_emulator()


def write_audio_wav(raw_audio, wav_path):
    """Wrap ZEsarUX's 15.6 kHz unsigned mono PCM capture in a WAV container."""
    with wave.open(str(wav_path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(1)
        output.setframerate(15600)
        output.writeframes(raw_audio)


def preserve_partial_audio(raw_path, output_dir, case_name, profile_name, checkpoints,
                           active_step, active_step_name):
    """Split captured audio into completed steps and the incomplete step."""
    if not raw_path.is_file():
        return
    audio = raw_path.read_bytes()
    offset = 0
    for checkpoint in checkpoints:
        end_offset = min(max(checkpoint["end_offset"], offset), len(audio))
        if end_offset > offset:
            wav_path = output_dir / output_basename(
                case_name, profile_name, checkpoint["step"], checkpoint["name"], ".wav")
            write_audio_wav(audio[offset:end_offset], wav_path)
            print(f"      audio -> {wav_path.name}", flush=True)
        offset = end_offset
    if len(audio) > offset:
        partial_name = f"{active_step_name}-partial"
        wav_path = output_dir / output_basename(
            case_name, profile_name, active_step, partial_name, ".wav")
        write_audio_wav(audio[offset:], wav_path)
        print(f"      audio partial -> {wav_path.name}", flush=True)
    raw_path.unlink(missing_ok=True)


def check_audio_expectations(audio, expectations):
    """Check expected held levels and signal range in captured audio."""
    minimum = expectations.get("minimum_level_samples", 1)
    levels = expectations.get("levels_in_order", [])
    offset = 0
    for level in levels:
        pattern = bytes((level,)) * minimum
        position = audio.find(pattern, offset)
        if position < 0:
            return f"audio capture did not hold output level {level} for {minimum} samples"
        offset = position + minimum

    signal_range = expectations.get("range")
    minimum_peak_to_peak = expectations.get("minimum_peak_to_peak")
    if minimum_peak_to_peak is not None:
        peak_to_peak = max(audio) - min(audio) if audio else 0
        if peak_to_peak < minimum_peak_to_peak:
            return (f"audio peak-to-peak amplitude is {peak_to_peak}; "
                    f"expected at least {minimum_peak_to_peak}")
    if signal_range:
        low, high = signal_range
        if min(audio) >= low or max(audio) <= high:
            return ("audio signal stayed within the expected range "
                    f"({min(audio)}..{max(audio)}; expected below {low} and above {high})")
    level_range = expectations.get("level_range")
    if level_range:
        low, high = level_range
        if min(audio) < low or max(audio) > high:
            return ("audio levels were outside the expected range "
                    f"({min(audio)}..{max(audio)}; expected {low}..{high})")
    return None


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
    manifest = json.loads(Path(manifest_path).read_text(encoding="utf-8"))
    extra_args.extend(manifest.get("emulator_args", []))
    if manifest.get("romfile"):
        extra_args.extend(("--romfile", manifest["romfile"]))
    emulator_images = manifest.get("emulator_images", {})
    if emulator_images.get("mmc"):
        extra_args.extend(("--mmc-file", emulator_images["mmc"], "--enable-mmc",
                           "--mmc-no-persistent-writes"))
    if emulator_images.get("ide"):
        extra_args.extend(("--ide-file", emulator_images["ide"], "--enable-ide",
                           "--ide-no-persistent-writes"))
    if emulator_images.get("trd"):
        extra_args.extend(("--trd-file", emulator_images["trd"], "--enable-trd",
                           "--trd-no-persistent-writes"))
    if audio_capture:
        audio_raw_path.unlink(missing_ok=True)
        extra_args.extend(("--enableaudiodac", "--audiodactype", "Covox Pentagon",
                           "--aofile", str(audio_raw_path)))
    session = TestSession(
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
    pending_step = 1
    completion_detail = []
    completion_failure_inline = False
    audio_step_names = list((audio_expectations or {}).get("steps", {}))
    active_step = 0
    active_step_name = audio_step_names[0] if audio_step_names else "step"
    session_completed = False
    try:
        if live_steps:
            print(step_prefix(pending_step), end="", flush=True)
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
            if (state != manifest["protocol"]["states"]["idle"] and
                    not done_with_more):
                completion_suffix = ""
                if status == 1:
                    completion_detail, completion_suffix = completion_failure_detail(log)
                if pending_step is not None:
                    if not steps:
                        final_status = {0: "PASS", 1: "FAIL", 2: "SKIP"}.get(status, "FAIL")
                        completion_failure_inline = bool(
                            final_status == "FAIL" and completion_suffix)
                        prefix = "" if live_steps else step_prefix(pending_step)
                        suffix = f" {completion_suffix}" if completion_failure_inline else ""
                        print(f"{prefix}{console_label(final_status)}{suffix}", flush=True)
                    elif live_steps:
                        print("\r\033[2K", end="", flush=True)
                    pending_step = None
                break
            name = step_name(log)
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
            prefix = "" if live_steps and pending_step is not None else step_prefix(step + 1)
            print(f"{prefix}{console_label(step_status)} {name}", flush=True)
            pending_step = None
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
            if not audio_capture or active_step < len(audio_step_names):
                pending_step = step + 2
                if live_steps:
                    print(step_prefix(pending_step), end="", flush=True)
            session.next_step()
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
    except Exception:
        if pending_step is not None:
            prefix = "" if live_steps else step_prefix(pending_step)
            print(f"{prefix}{console_label('FAIL')}", flush=True)
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


# --------------------------------------------------------------------------
# PNG comparison
# --------------------------------------------------------------------------


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def decode_png(path):
    data = Path(path).read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        raise FrameworkError(f"not a PNG file: {path}")
    position = 8
    width = height = None
    bit_depth = color_type = interlace = None
    compressed = bytearray()
    while position < len(data):
        length = struct.unpack(">I", data[position:position + 4])[0]
        tag = data[position + 4:position + 8]
        payload = data[position + 8:position + 8 + length]
        position += 12 + length
        if tag == b"IHDR":
            width, height, bit_depth, color_type, _, _, interlace = struct.unpack(">IIBBBBB", payload)
        elif tag == b"IDAT":
            compressed.extend(payload)
        elif tag == b"IEND":
            break
    if None in (width, height, bit_depth, color_type, interlace):
        raise FrameworkError(f"PNG has no IHDR: {path}")
    if bit_depth != 8 or color_type != 2 or interlace != 0:
        raise FrameworkError(f"only 8-bit RGB non-interlaced PNG is supported: {path}")
    raw = zlib.decompress(bytes(compressed))
    stride = width * 3
    pixels = bytearray(width * height * 3)
    previous = bytearray(stride)
    offset = 0
    for row in range(height):
        filter_type = raw[offset]
        offset += 1
        line = bytearray(raw[offset:offset + stride])
        offset += stride
        if filter_type == 1:
            for index in range(3, stride):
                line[index] = (line[index] + line[index - 3]) & 0xFF
        elif filter_type == 2:
            for index in range(stride):
                line[index] = (line[index] + previous[index]) & 0xFF
        elif filter_type == 3:
            for index in range(stride):
                left = line[index - 3] if index >= 3 else 0
                line[index] = (line[index] + ((left + previous[index]) >> 1)) & 0xFF
        elif filter_type == 4:
            for index in range(stride):
                left = line[index - 3] if index >= 3 else 0
                up = previous[index]
                up_left = previous[index - 3] if index >= 3 else 0
                estimate = left + up - up_left
                pa = abs(estimate - left)
                pb = abs(estimate - up)
                pc = abs(estimate - up_left)
                predictor = left if pa <= pb and pa <= pc else (up if pb <= pc else up_left)
                line[index] = (line[index] + predictor) & 0xFF
        elif filter_type != 0:
            raise FrameworkError(f"unsupported PNG filter {filter_type} in {path}")
        pixels[row * stride:(row + 1) * stride] = line
        previous = line
    return width, height, pixels


def png_chunk(tag, payload):
    body = tag + payload
    return struct.pack(">I", len(payload)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)


def encode_png(path, width, height, pixels):
    raw = bytearray()
    stride = width * 3
    for row in range(height):
        raw.append(0)
        raw.extend(pixels[row * stride:(row + 1) * stride])
    header = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    data = (PNG_SIGNATURE + png_chunk(b"IHDR", header) +
            png_chunk(b"IDAT", zlib.compress(bytes(raw), 6)) +
            png_chunk(b"IEND", b""))
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_bytes(data)


def compare_data_files(expected_path, actual_path, diff_path):
    left = expected_path.read_bytes()
    right = actual_path.read_bytes()
    if left == right:
        return None
    if actual_path.suffix == ".bin":
        limit = min(len(left), len(right))
        first = next((index for index in range(limit) if left[index] != right[index]), limit)
        diff_path.write_text(
            f"binary differs at offset {first} (expected {len(left)} bytes, actual {len(right)} bytes)\n"
            f"expected: {left[max(0, first - 8):first + 24].hex(' ')}\n"
            f"actual:   {right[max(0, first - 8):first + 24].hex(' ')}\n",
            encoding="utf-8")
        return (f"{actual_path.name}: binary differs at offset {first} "
                f"(expected {len(left)} bytes, actual {len(right)} bytes)")
    left_lines = left.decode("latin1").splitlines(keepends=True)
    right_lines = right.decode("latin1").splitlines(keepends=True)
    diff = list(difflib.unified_diff(left_lines, right_lines,
                                     fromfile="golden/" + expected_path.name,
                                     tofile=actual_path.name))
    diff_path.write_text("".join(diff), encoding="utf-8")
    first = next((line for line in diff
                  if line[:1] in "+-" and not line.startswith(("+++", "---"))), "")
    return f"{actual_path.name}: text differs ({first.rstrip()!r}); see {diff_path}"


def compare_screenshots(expected_path, actual_path, diff_path, region=None):
    expected = decode_png(expected_path)
    actual = decode_png(actual_path)
    if expected[0] != actual[0] or expected[1] != actual[1]:
        raise TestFailure(
            f"screenshot size differs: {expected[0]}x{expected[1]} != {actual[0]}x{actual[1]}")
    width, height, left = expected
    right = actual[2]
    x, y, region_width, region_height = region or (0, 0, width, height)
    if not (0 <= x < x + region_width <= width and 0 <= y < y + region_height <= height):
        raise TestFailure(f"screenshot comparison region is outside {width}x{height}")
    count = 0
    first = None
    diff = bytearray(len(left))
    for row in range(y, y + region_height):
        start = (row * width + x) * 3
        for index in range(start, start + region_width * 3, 3):
            if left[index:index + 3] != right[index:index + 3]:
                count += 1
                if first is None:
                    first = (index // 3 % width, row)
                diff[index:index + 3] = b"\xff\x00\xff"
            else:
                diff[index] = left[index] // 3
                diff[index + 1] = left[index + 1] // 3
                diff[index + 2] = left[index + 2] // 3
    if count:
        encode_png(diff_path, width, height, diff)
    return count, first


# --------------------------------------------------------------------------
# Commands
# --------------------------------------------------------------------------

class TestSuite:
    """Run a suite with target-specific compiler options and mapper writes."""

    def __init__(self, tests, machine, *, common_tests=None):
        self.tests = common_tests if common_tests is not None else tests
        self.machine = machine
        self.case_prefix = f"{machine}/" if common_tests is not None else ""
        self.cases = self.tests / "cases"
        self.build_dir = self.tests / "build"
        self.output_dir = self.tests / "out"
        if common_tests is not None:
            self.build_dir /= machine.lower()
            self.output_dir /= machine.lower()
        self.profiles_file = tests / "profiles.json"

    def build_target(self, profile, verbose):
        """Prepare the target library and return its compiler configuration."""
        raise NotImplementedError

    def page_write(self, window, page):
        """Return the port and value that map a physical RAM page."""
        raise NotImplementedError

    def launch_ports(self, profile, layout):
        """Return the initialization writes before loading the RAM blocks."""
        raise NotImplementedError

    def run(self):
        try:
            return self.main()
        except FrameworkError as error:
            print(f"{console_label('error', stream=sys.stderr)}: {error}", file=sys.stderr)
            return 2

    def load_profiles(self):
        with open(self.profiles_file, "r", encoding="utf-8") as stream:
            profiles = json.load(stream)
        return profiles

    def case_relative_path(self, path):
        return path.relative_to(self.cases).with_suffix("")

    def select_case_paths(self, selected, filter_re):
        paths = {self.case_relative_path(path).as_posix(): path
                 for path in sorted(self.cases.rglob("*.c")) if not path.name.startswith("_")}
        matched = set()
        for selector in selected or ():
            if selector in paths:
                matched.add(paths[selector])
                continue
            prefix = selector.rstrip("/") + "/"
            descendants = [path for name, path in paths.items() if name.startswith(prefix)]
            if descendants:
                matched.update(descendants)
                continue
            names = [name for name, path in paths.items() if path.stem == selector]
            if not names:
                raise FrameworkError(f"unknown case or directory {selector!r}; use 'list' to see cases")
            if len(names) > 1:
                raise FrameworkError(f"ambiguous case {selector!r}; choose one of {', '.join(names)}")
            matched.add(paths[names[0]])

        return [path for path in paths.values() if (not selected or path in matched)
                and (not filter_re or filter_re.search(path.stem))]

    def discover_cases(self, selected, filter_re):
        cases = []
        for path in self.select_case_paths(selected, filter_re):
            meta = {}
            meta_path = path.with_suffix(".json")
            if meta_path.is_file():
                with open(meta_path, "r", encoding="utf-8") as stream:
                    meta = json.load(stream)
            meta.update(meta.pop("targets", {}).get(self.machine.lower(), {}))
            cases.append((path, meta))
        return cases

    def prepare_emulator_images(self, case_name, meta):
        config = meta.get("emulator_images")
        if not config:
            return {}
        generator = (self.tests / config["generator"]).resolve()
        if not generator.is_file():
            raise FrameworkError(f"emulator image generator is missing: {generator}")
        image_dir = self.build_dir / case_name / "emulator_images"
        image_dir.mkdir(parents=True, exist_ok=True)
        result = subprocess.run([sys.executable, str(generator), str(image_dir)],
                                capture_output=True, text=True)
        if result.returncode != 0:
            detail = (result.stdout + result.stderr).strip()
            raise FrameworkError("emulator image preparation failed" +
                                 (f":\n{detail}" if detail else ""))
        images = {}
        for device in ("mmc", "ide", "trd"):
            filename = config.get(device)
            if filename:
                path = image_dir / filename
                if not path.is_file():
                    raise FrameworkError(f"image generator did not create {path.name}")
                images[device] = str(path.resolve())
        return images

    def build_fingerprint(self, case_path, profile, case_sources, target, romfile):
        digest = hashlib.sha256()
        parts = [*case_sources, case_path.with_suffix(".json"), self.profiles_file,
                 Path(__file__), PROTOCOL_FILE, ZX_HOST_SOURCE, ZXTEST_SOURCE,
                 TEST_SUPPORT_INCLUDE / "zx_host.h", TEST_SUPPORT_INCLUDE / "zx_test.h",
                 *target.sources, *target.inputs]
        if romfile:
            parts.append(romfile)
        for path in parts:
            digest.update(str(path).encode())
            if path.is_file():
                digest.update(file_digest(path).encode())
        digest.update(json.dumps(profile, sort_keys=True).encode())
        digest.update(ZCC.encode())
        return digest.hexdigest()

    def block(self, name, address, page, window, category, filename, length):
        port, value = self.page_write(window, page)
        return {
            "name": name,
            "address": address,
            "physical_page": page,
            "window": window,
            "port": port,
            "raw_page": value,
            "category": category,
            "filename": filename,
            "length": length,
        }

    def compile_case(self, case_path, meta, profile, verbose=False, show_profile=True):
        emulator_args = meta.get("emulator_args", [])
        if not isinstance(emulator_args, list) or any(not isinstance(arg, str) for arg in emulator_args):
            raise FrameworkError("case emulator_args must be a list of strings")
        test_rom = os.environ.get("ZXEVO_TEST_ROM") if profile.get("use_test_rom") else None
        romfile = Path(test_rom).resolve() if test_rom else None
        if romfile and not romfile.is_file():
            raise FrameworkError(f"test ROM is missing: {romfile}")
        layout = layout_values(profile["layout"])
        case_name = case_path.stem
        case_relative = self.case_relative_path(case_path)
        out_dir = self.build_dir / case_relative
        out_dir.mkdir(parents=True, exist_ok=True)
        binary = out_dir / case_name
        map_path = binary.with_suffix(".map")

        sources = [case_path]
        for extra in meta.get("sources", []):
            sources.append((case_path.parent / extra).resolve())
        case_sources = list(sources)
        emulator_images = self.prepare_emulator_images(case_relative, meta)
        if meta.get("emulator_images"):
            case_sources.append((self.tests / meta["emulator_images"]["generator"]).resolve())

        build_label = self.case_prefix + case_name
        if show_profile:
            build_label += f" [{profile['name']}]"
        print(f"{console_label('BUILD', 6)}{build_label}: ", end="", flush=True)
        target = self.build_target(profile, verbose)
        fingerprint = self.build_fingerprint(case_path, profile, case_sources, target, romfile)
        stamp = out_dir / "stamp"
        manifest_path = out_dir / "manifest.json"
        if not (stamp.is_file() and stamp.read_text() == fingerprint + "\n" and manifest_path.is_file()):
            generated_header = out_dir / "zx_host_config.h"
            subprocess.run(
                [sys.executable, str(TEST_RUNNER / "zx_host" / "generate_header.py"),
                 str(PROTOCOL_FILE), str(generated_header)],
                check=True, capture_output=True, text=True)
            command = [
                ZCC,
                *target.flags,
                "-clib=classic",
                "-compiler=sdcc",
                "--reserve-regs-iy",
                "-SO3",
                "-m",
                f"-I{TEST_SUPPORT_INCLUDE}",
                f"-I{out_dir}",
                f"-I{self.cases}",
                f"-pragma-define:CRT_MODEL=0",
                f"-pragma-define:MMAP=-1",
                f"-pragma-define:CRT_ORG_CODE=0x{layout['code_org']:X}",
                f"-pragma-define:CRT_ORG_DATA=0x{layout['data_org']:X}",
                f"-pragma-define:CRT_ORG_BSS=0x{layout['bss_org']:X}",
                f"-pragma-define:REGISTER_SP=0x{layout['stack_org']:X}",
            ]
            command.extend(profile.get("cflags", []))
            command.extend(f"-D{value}" for value in profile.get("defines", []))
            command.extend(f"-D{value}" for value in meta.get("defines", []))
            command.extend(meta.get("cflags", []))
            command.extend(f"-l{name}" for name in profile.get("library", {}).get("extra_libs", []))
            command.append("-o")
            command.append(str(binary))
            command.extend(str(path) for path in sources)
            command.extend(str(path) for path in (*target.sources, ZXTEST_SOURCE, ZX_HOST_SOURCE))
            if verbose:
                print("  " + " ".join(command))
            result = run_test_build(command, crash_log=out_dir / "build.sigsegv.log",
                                    env={**os.environ, **target.env})
            (out_dir / "build.log").write_text(result.stdout + result.stderr, encoding="utf-8")
            if result.returncode != 0:
                tail = (result.stdout + result.stderr).strip().splitlines()[-15:]
                raise FrameworkError("compile failed:\n" + "\n".join(tail))
            if not map_path.is_file():
                raise FrameworkError(f"compiler did not produce {map_path.name}")

            symbols = parse_map(map_path)
            code_org = map_symbol(symbols, "start")
            rodata_end = symbols.get("__RODATA_END_head", symbols.get("__CODE_END_tail"))
            data_org = map_symbol(symbols, "__DATA_head")
            data_end = map_symbol(symbols, "__DATA_END_tail")
            bss_org = map_symbol(symbols, "__BSS_head")
            bss_end = map_symbol(symbols, "__BSS_END_tail")
            stack = map_symbol(symbols, "__register_sp")
            if code_org != layout["code_org"]:
                raise FrameworkError(f"start symbol is 0x{code_org:04X}, expected 0x{layout['code_org']:04X}")
            if data_org != layout["data_org"] or bss_org != layout["bss_org"]:
                raise FrameworkError("linked DATA/BSS addresses do not match the profile layout")
            if stack != layout["stack_org"]:
                raise FrameworkError("linked stack does not match the profile layout")
            protocol = json.loads(PROTOCOL_FILE.read_text(encoding="utf-8"))
            code_window = layout["code_window"]
            code_window_end = (code_window + 1) * PAGE_SIZE
            if code_window == 0 and rodata_end > protocol["header_address"]:
                raise FrameworkError(
                    f"test is too large: code+rodata ends at 0x{rodata_end:04X}, "
                    f"the ZXHost mailbox starts at 0x{protocol['header_address']:04X}")
            if code_window != 0 and rodata_end > code_window_end:
                raise FrameworkError(
                    f"code+rodata ends at 0x{rodata_end:04X}, past W{code_window} end "
                    f"0x{code_window_end:04X}")
            if code_window != 0 and layout["stack_org"] <= rodata_end:
                raise FrameworkError("stack overlaps code+rodata in the test code window")
            log_end = protocol["log_address"] + protocol["log_size"]
            if layout["data_org"] < log_end:
                raise FrameworkError(
                    f"DATA starts at 0x{layout['data_org']:04X}, inside the ZXHost log ending at 0x{log_end:04X}")
            if data_end > bss_org:
                raise FrameworkError(f"DATA ends at 0x{data_end:04X}, past BSS at 0x{bss_org:04X}")
            if bss_end + 0x400 > stack:
                raise FrameworkError(f"BSS ends at 0x{bss_end:04X}, too close to the stack at 0x{stack:04X}")
            if log_end > stack:
                raise FrameworkError("ZXHost log overlaps the stack")

            code_data = binary.read_bytes()
            expected_length = rodata_end - layout["code_org"]
            if len(code_data) != expected_length:
                raise FrameworkError(
                    f"code image is {len(code_data)} bytes, map says {expected_length}; "
                    "the link layout is inconsistent")
            split = PAGE_SIZE - layout["code_org"] if code_window == 0 else len(code_data)
            code0 = out_dir / "code0.bin"
            code0.write_bytes(code_data[:split])
            blocks = []
            if code_window == 0:
                generate_vectors(out_dir / "vectors.bin")
                blocks.append(self.block("VECTORS", 0, layout["code_page"], 0,
                                         "vectors", "vectors.bin", 256))
            blocks.append(self.block("CODE", layout["code_org"], layout["code_page"], code_window,
                                     "code", code0.name, len(code_data[:split])))
            if code_window == 0 and len(code_data) > split:
                code1 = out_dir / "code1.bin"
                code1.write_bytes(code_data[split:])
                blocks.append(self.block("CODE1", PAGE_SIZE, layout["data_page"], 1,
                                         "code", code1.name, len(code_data) - split))
            data_bin = binary.with_name(binary.name + "_DATA.bin")
            if data_bin.is_file() and data_bin.stat().st_size:
                data_len = data_bin.stat().st_size
                if data_len != data_end - data_org:
                    raise FrameworkError("DATA image size does not match the map")
                blocks.append(self.block("DATA", data_org, layout["data_page"], 1,
                                         "data", data_bin.name, data_len))
            manifest = {
                "protocol": protocol,
                "machine": self.machine,
                "launch": {"boot_cycles": 2_000_000, "ports": self.launch_ports(profile, layout)},
                "entry": layout["code_org"],
                "stack": layout["stack_org"],
                "blocks": blocks,
            }
            if romfile:
                manifest["romfile"] = str(romfile)
            if emulator_args:
                manifest["emulator_args"] = emulator_args
            if emulator_images:
                manifest["emulator_images"] = emulator_images
            manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
            stamp.write_text(fingerprint + "\n", encoding="utf-8")
        print(f"code={binary.stat().st_size}B", flush=True)
        return manifest_path, out_dir

    def enumerate_runs(self, args, profiles):
        runs = []
        for case_path, meta in self.discover_cases(args.case, args.filter and re.compile(args.filter)):
            chosen = case_profiles(meta, profiles, set(args.profile or []))
            if not chosen:
                continue
            runs.append((case_path, meta, chosen))
        return runs


    def command_list(self, args, profiles):
        runs = self.enumerate_runs(args, profiles)
        if not runs:
            print("no cases")
            return 0
        for case_path, meta, chosen in runs:
            shots = 0
            for profile in chosen:
                shots += len(expected_files(case_path, profile["name"]))
            description = meta.get("description", "")
            name = self.case_prefix + self.case_relative_path(case_path).as_posix()
            print(f"{name:32s} profiles={','.join(p['name'] for p in chosen):24s} "
                  f"expected={shots:2d} {description}".rstrip())
        return 0


    def command_build(self, args, profiles):
        failures = 0
        for case_path, meta, chosen in self.enumerate_runs(args, profiles):
            for profile in chosen:
                try:
                    self.compile_case(case_path, meta, profile, args.verbose)
                except FrameworkError as error:
                    failures += 1
                    print()
                    print(f"{console_label('BUILD FAIL')} {self.case_prefix}{case_path.stem} [{profile['name']}]: {error}")
        return 1 if failures else 0


    def clean_outputs(self, selected, filter_re):
        if selected or filter_re:
            for case_path in self.select_case_paths(selected, filter_re):
                relative_case = self.case_relative_path(case_path)
                shutil.rmtree(self.build_dir / relative_case, ignore_errors=True)
                output_dir = self.output_dir / relative_case.parent
                for artifact in output_dir.glob(f"{case_path.stem}.*"):
                    if artifact.is_file():
                        artifact.unlink(missing_ok=True)
            return
        shutil.rmtree(self.build_dir, ignore_errors=True)
        shutil.rmtree(self.output_dir, ignore_errors=True)
        for cache in list(self.tests.rglob("__pycache__")):
            if cache.is_dir():
                shutil.rmtree(cache, ignore_errors=True)


    def command_check(self, args, profiles):
        failures = 0
        errors = 0
        total_outputs = 0
        runs = self.enumerate_runs(args, profiles)
        zesarux = find_zesarux(args.zesarux)
        for case_path, meta, chosen in runs:
            for profile in chosen:
                name = case_path.stem
                display_name = self.case_prefix + name
                relative_case = self.case_relative_path(case_path)
                build_dir = self.build_dir / relative_case
                output_dir = self.output_dir / relative_case.parent
                label = f"{display_name} [{profile['name']}]"
                try:
                    if args.no_build:
                        manifest_path = build_dir / "manifest.json"
                        if not manifest_path.is_file():
                            raise FrameworkError(f"no previous build at {manifest_path.parent}")
                    else:
                        manifest_path, _ = self.compile_case(
                            case_path, meta, profile, args.verbose, show_profile=False)
                    output_dir.mkdir(parents=True, exist_ok=True)
                except FrameworkError as error:
                    if not args.no_build:
                        print()
                    print(f"{console_label('BUILD FAIL')} {label}: {error}")
                    failures += 1
                    continue
                timeout = args.timeout or meta.get("timeout", 30)
                print(f"{console_label('RUN', 6)}{label}", flush=True)
                try:
                    result = run_session(manifest_path, name, profile["name"],
                                         zesarux, args.port, timeout, output_dir, args.verbose,
                                         meta.get("audio_capture", False),
                                         meta.get("audio_expectations"),
                                         meta.get("audio_step_flush_cycles", 0),
                                         meta.get("emulator_steps"))
                except TimeoutError as error:
                    print(f"{console_label('FAIL')} {display_name}: test timeout: {error}")
                    failures += 1
                    continue
                except (OSError, ValueError, RuntimeError) as error:
                    print(f"{console_label('FAIL')} {display_name}: emulator error: {error}")
                    errors += 1
                    continue
                case_failures = []
                case_failures.extend(result["audio_errors"])
                case_failures.extend(result["step_errors"])
                do_update = args.update and result["status"] == 0
                if args.update and result["status"] != 0:
                    case_failures.append("target reported FAIL; expected files were not updated")
                produced = set()
                for step, step_title, actual in result["shots"]:
                    total_outputs += 1
                    expected = case_path.parent / actual.name
                    produced.add(actual.name)
                    if do_update:
                        shutil.copy2(actual, expected)
                        continue
                    if not expected.is_file():
                        case_failures.append(f"missing expected {expected.relative_to(self.tests)}")
                        continue
                    try:
                        count, first = compare_screenshots(
                            expected, actual, output_dir / f"{actual.stem}.diff.png",
                            meta.get("emulator_steps", {}).get(step_title, {}).get("region"))
                    except (TestFailure, FrameworkError) as error:
                        case_failures.append(str(error))
                        continue
                    if count:
                        where = f"first at {first[0]},{first[1]}" if first else ""
                        case_failures.append(
                            f"{actual.name}: {count} pixel(s) differ ({where}); "
                            f"see {output_dir / (actual.stem + '.diff.png')}")
                for step, step_title, actual, kind in result["data"]:
                    total_outputs += 1
                    expected = case_path.parent / actual.name
                    produced.add(actual.name)
                    if do_update:
                        shutil.copy2(actual, expected)
                        continue
                    if not expected.is_file():
                        case_failures.append(f"missing expected {expected.relative_to(self.tests)}")
                        continue
                    try:
                        message = compare_data_files(
                            expected, actual, output_dir / f"{actual.stem}.diff.txt")
                    except (TestFailure, FrameworkError, OSError) as error:
                        case_failures.append(str(error))
                        continue
                    if message:
                        case_failures.append(message)
                case_failures.extend(result.get("data_errors", []))
                for orphan in expected_files(case_path, profile["name"]):
                    if orphan.name in produced:
                        continue
                    if do_update:
                        orphan.unlink()
                        print(f"     removed stale golden {orphan.relative_to(self.tests)}")
                    else:
                        case_failures.append(
                            f"golden without a produced output: {orphan.relative_to(self.tests)}")
                failed_steps = [step for step in result["steps"] if step["status"] == 1]
                for step in failed_steps:
                    detail = " | ".join(line.strip() for line in step["log"].splitlines()[1:]
                                        if line.strip() and not line.startswith("DATA "))
                    case_failures.append(
                        f"step {step['step']}: {step['name']}: {detail or 'FAIL'}")
                if result["status"] == 1 and not failed_steps:
                    detail = result.get("completion_detail", [])
                    case_failures.extend(detail or ["target reported FAIL"])
                report = {
                    "case": name,
                    "machine": self.machine,
                    "profile": profile["name"],
                    "status": result["status"],
                    "skips": result["skips"],
                    "steps": result["steps"],
                    "screenshots": [
                        {"step": step, "name": step_title, "file": actual.name}
                        for step, step_title, actual in result["shots"]
                    ],
                    "data": [
                        {"step": step, "name": step_title, "file": actual.name, "kind": kind}
                        for step, step_title, actual, kind in result["data"]
                    ],
                    "failures": case_failures,
                    "updated": do_update,
                }
                report_path = output_dir / f"{output_prefix(name, profile['name'])}report.json"
                report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
                if case_failures:
                    failures += 1
                    print(f"{console_label('FAIL')} {display_name}")
                    for line in case_failures:
                        if (result.get("completion_failure_inline") and
                                line in result.get("completion_detail", [])):
                            continue
                        print(f"     {line}")
                    if args.fail_fast:
                        return 1
                else:
                    skip_text = f", {result['skips']} skipped step(s)" if result["skips"] else ""
                    outputs = len(result["shots"]) + len(result["data"])
                    print(f"{console_label('PASS', 6)}{display_name} ({outputs} output(s){skip_text})")
        if args.update:
            print(f"updated {total_outputs} output(s)")
        if errors:
            return 2
        return 1 if failures else 0


    def main(self):
        common = argparse.ArgumentParser(add_help=False)
        common.add_argument("--case", action="append", metavar="PATH",
                            help="case or directory under cases/ (repeatable)")
        common.add_argument("--profile", action="append", help="only this profile (repeatable)")
        common.add_argument("--filter", help="regular expression on case names")
        common.add_argument("--update", action="store_true", help="write actual screenshots as expected")
        common.add_argument("--no-build", action="store_true", help="reuse the last built binaries")
        common.add_argument("--fail-fast", action="store_true", help="stop after the first failing case")
        common.add_argument("--timeout", type=float, help="seconds per test step")
        common.add_argument("--port", type=int, default=10040, help="ZRCP port")
        common.add_argument("--zesarux", help="ZEsarUX executable")
        common.add_argument("--verbose", action="store_true")

        parser = argparse.ArgumentParser(description=__doc__,
                                         formatter_class=argparse.RawDescriptionHelpFormatter)
        subparsers = parser.add_subparsers(dest="command")
        subparsers.add_parser("list", parents=[common], help="list discovered cases")
        subparsers.add_parser("build", parents=[common], help="build cases and manifests")
        subparsers.add_parser("check", parents=[common], help="run cases and compare screenshots")
        subparsers.add_parser("clean", parents=[common], help="remove build/, out/ and local Python caches")

        argv = sys.argv[1:]
        if not argv or argv[0].startswith("-"):
            argv = ["check"] + argv
        args = parser.parse_args(argv)
        if args.command == "clean":
            self.clean_outputs(args.case, args.filter and re.compile(args.filter))
            return 0
        profiles = self.load_profiles()
        if args.command == "list":
            return self.command_list(args, profiles)
        if args.command == "build":
            return self.command_build(args, profiles)
        return self.command_check(args, profiles)
