"""Prepare private Python dependencies and restart a command-line entry point."""

from contextlib import contextmanager
import errno
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time


@contextmanager
def _setup_lock(directory):
    """Serialize setup across concurrent processes using the same environment."""
    directory.parent.mkdir(parents=True, exist_ok=True)
    with directory.with_name(directory.name + ".lock").open("a+b") as lock:
        if os.name == "nt":
            import msvcrt
            if lock.seek(0, os.SEEK_END) == 0:
                lock.write(b"\0")
                lock.flush()
            lock.seek(0)
            while True:
                try:
                    msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
                    break
                except OSError as error:
                    if error.errno not in (errno.EACCES, errno.EAGAIN, errno.EDEADLK):
                        raise
                    time.sleep(0.1)
        else:
            import fcntl
            fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            yield
        finally:
            if os.name == "nt":
                lock.seek(0)
                msvcrt.locking(lock.fileno(), msvcrt.LK_UNLCK, 1)
            else:
                fcntl.flock(lock, fcntl.LOCK_UN)


def _prepare_environment(requirements, directory):
    python = directory / ("Scripts/python.exe" if os.name == "nt" else "bin/python")
    stamp = directory / ".dependencies.json"
    runtime = {"version": sys.version, "base_prefix": sys.base_prefix,
               "location": str(directory)}
    expected = {"runtime": runtime,
                "requirements": hashlib.sha256(requirements.read_bytes()).hexdigest()}
    with _setup_lock(directory):
        try:
            installed = json.loads(stamp.read_text())
        except (OSError, ValueError):
            installed = {}
        if not isinstance(installed, dict):
            installed = {}
        if python.is_file() and installed == expected:
            return python
        print(f"Preparing Python dependencies: {requirements}", file=sys.stderr, flush=True)
        # Never clear a user's environment: this directory belongs to the tool,
        # and EnvBuilder can repair an interrupted creation without deleting it.
        if not python.is_file() or installed.get("runtime") != runtime:
            import venv
            venv.EnvBuilder(with_pip=True).create(directory)
        # Keep failed/interrupted installations unmarked, so the next run retries.
        stamp.unlink(missing_ok=True)
        result = subprocess.run(
            [str(python), "-m", "pip", "install", "--disable-pip-version-check",
             "--requirement", str(requirements)], cwd=requirements.parent, stdout=sys.stderr)
        if result.returncode:
            raise ValueError("could not install Python dependencies; see pip output above and retry")
        temporary = stamp.with_suffix(".tmp")
        temporary.write_text(json.dumps(expected, sort_keys=True) + "\n")
        temporary.replace(stamp)
    return python


def ensure_environment(requirements, *, directory=None):
    """Use the managed interpreter for this CLI, preserving cwd and arguments.

    requirements is a pip requirements file. The default directory is
    build/python-<requirements stem> next to that file; directory overrides it.
    Call only in a CLI entry point, after parsing arguments and before importing
    external packages. --help and importing library functions then have no setup
    side effects. Requires Python3.11+ with venv/ensurepip available.
    """
    # The parent has completed setup before re-exec. Do not reinstall from inside
    # the interpreter being managed, including during a concurrent requirements edit.
    requirements = Path(requirements).resolve()
    directory = (Path(directory).resolve() if directory is not None else
                 requirements.parent / "build" / ("python-" + requirements.stem))
    if Path(sys.prefix).resolve() == directory:
        return
    try:
        python = _prepare_environment(requirements, directory)
        os.execv(str(python), [str(python), *sys.orig_argv[1:]])
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        raise ValueError(f"Python environment setup failed: {error}") from error
