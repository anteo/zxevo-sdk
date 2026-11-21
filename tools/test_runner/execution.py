"""Schedule prepared cases on independent ZEsarUX ports."""

import multiprocessing
import signal
import socket
import time
from contextlib import redirect_stderr, redirect_stdout
from dataclasses import dataclass
from multiprocessing.connection import wait
from pathlib import Path

from .emulator import run_session
from .support import FrameworkError, console_label


@dataclass
class PreparedCase:
    source: Path
    relative: Path
    manifest: Path
    meta: dict
    profile: dict
    label: str

    @property
    def step_log(self):
        return self.manifest.parent / f"{self.relative.name}.steps.log"


def execute(case, zesarux, port, args):
    start = time.monotonic()
    try:
        meta = case.meta
        result = run_session(case.manifest, case.relative.name, case.profile["name"],
                             zesarux, port, args.timeout or meta.get("timeout", 30),
                             case.manifest.parent, args.verbose, meta.get("audio_capture", False),
                             meta.get("audio_expectations"), meta.get("audio_step_flush_cycles", 0),
                             meta.get("emulator_steps"))
    except (OSError, ValueError, RuntimeError) as error:
        result = error
    return result, time.monotonic() - start


def stop_worker(signum, frame):
    # Unwind run_session's finally block so it closes and reaps its emulator.
    raise KeyboardInterrupt


def run_worker(sender, case, zesarux, port, args):
    # The parent handles Ctrl+C and signals each worker once during cleanup.
    signal.signal(signal.SIGINT, signal.SIG_IGN)
    signal.signal(signal.SIGTERM, stop_worker)
    with sender:
        try:
            with case.step_log.open("w", encoding="utf-8") as log, redirect_stdout(log), redirect_stderr(log):
                outcome = execute(case, zesarux, port, args)
            sender.send(outcome)
        except KeyboardInterrupt:
            pass
        except Exception as error:
            sender.send((RuntimeError(f"emulator worker: {type(error).__name__}: {error}"), None))


def emulator_results(cases, zesarux, args):
    if args.jobs == 1:
        for case in cases:
            print(f"{console_label('RUN', 6)}{case.label}", flush=True)
            yield case, *execute(case, zesarux, args.port, args)
        return

    ports = list(range(args.port + args.jobs - 1, args.port - 1, -1))
    # Detect an occupied port before a worker can connect to someone else's emulator.
    for port in ports:
        with socket.socket() as probe:
            probe.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            try:
                probe.bind(("", port))
            except OSError as error:
                raise FrameworkError(f"ZRCP port {port} is unavailable: {error}") from error

    context = multiprocessing.get_context("spawn")
    pending = {}

    def completed(timeout=None):
        for reader in wait(list(pending), timeout):
            process, case, port = pending[reader]
            try:
                result, elapsed = reader.recv()
            except EOFError:
                process.join()
                result = RuntimeError(f"emulator worker exited with status {process.exitcode}")
                elapsed = None
            process.join()
            del pending[reader]
            reader.close()
            process.close()
            ports.append(port)
            yield case, result, elapsed

    try:
        for case in cases:
            if pending:
                yield from completed(0 if ports else None)
            port = ports.pop()
            reader, sender = context.Pipe(duplex=False)
            process = context.Process(target=run_worker, args=(sender, case, zesarux, port, args))
            print(f"{console_label('RUN', 6)}{case.label}", flush=True)
            pending[reader] = process, case, port
            with sender:
                process.start()
        while pending:
            yield from completed()
    finally:
        for process, _, _ in pending.values():
            if process.is_alive():
                process.terminate()
        for reader, (process, _, _) in pending.items():
            if process.pid is not None:
                process.join()
            reader.close()
            process.close()
