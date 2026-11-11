#!/usr/bin/env python3
"""Launch ZEsarUX and control it through its remote command protocol.

Example::

    with ZesaruxRunner("/path/to/zesarux", machine="BaseConf",
                       extra_args=("--hardware-debug-ports",)) as runner:
        runner.remote.run_cycles(100000)
        runner.remote.save_screen("screen.png")
"""

import os
import shutil
import socket
import struct
import subprocess
import time
import zlib


def default_emulator():
    """Find the ZEsarUX executable in PATH or common install locations."""
    if os.environ.get("ZESARUX"):
        return os.environ["ZESARUX"]
    on_path = shutil.which("zesarux")
    if on_path:
        return on_path

    for candidate in (
        "/usr/bin/zesarux",
        "/usr/local/bin/zesarux",
        "/opt/zesarux/bin/zesarux",
        "/Applications/zesarux.app/Contents/MacOS/zesarux",
    ):
        if os.path.isfile(candidate) and os.access(candidate, os.X_OK):
            return candidate
    return "zesarux"


def bmp_to_png(source, destination):
    """Convert an uncompressed 24-bit BMP to PNG using only the stdlib."""
    with open(source, "rb") as image_file:
        bmp = image_file.read()

    if len(bmp) < 54 or bmp[:2] != b"BM":
        raise ValueError(f"not a valid BMP file: {source}")

    pixel_offset = struct.unpack_from("<I", bmp, 10)[0]
    dib_size = struct.unpack_from("<I", bmp, 14)[0]
    if dib_size < 40 or len(bmp) < 14 + dib_size:
        raise ValueError("unsupported BMP header")

    width, signed_height = struct.unpack_from("<ii", bmp, 18)
    planes, bits_per_pixel = struct.unpack_from("<HH", bmp, 26)
    compression = struct.unpack_from("<I", bmp, 30)[0]
    if width <= 0 or signed_height == 0 or planes != 1:
        raise ValueError("invalid BMP dimensions or plane count")
    if bits_per_pixel != 24 or compression != 0:
        raise ValueError("only uncompressed 24-bit BMP is supported")

    height = abs(signed_height)
    row_stride = (width * 3 + 3) & ~3
    pixels_end = pixel_offset + row_stride * height
    if pixel_offset < 14 + dib_size or pixels_end > len(bmp):
        raise ValueError("BMP pixel data is truncated")

    def png_chunk(tag, data):
        body = tag + data
        return (struct.pack(">I", len(data)) + body +
                struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF))

    raw = bytearray()
    row_order = range(height - 1, -1, -1) if signed_height > 0 else range(height)
    for row_number in row_order:
        start = pixel_offset + row_number * row_stride
        row = bmp[start:start + width * 3]
        raw.append(0)  # PNG filter: None
        for pixel in range(width):
            blue, green, red = row[pixel * 3:pixel * 3 + 3]
            raw.extend((red, green, blue))

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    png = (b"\x89PNG\r\n\x1a\n" + png_chunk(b"IHDR", ihdr) +
           png_chunk(b"IDAT", zlib.compress(raw, 6)) +
           png_chunk(b"IEND", b""))
    with open(destination, "wb") as png_file:
        png_file.write(png)


def _quote_argument(value):
    """Quote one ZRCP argument that may contain spaces."""
    return '"' + str(value).replace('"', '\\"') + '"'


class ZrcpClient:
    """Small synchronous client for ZEsarUX's ZRCP command protocol."""

    def __init__(self, port, host="127.0.0.1", timeout=30.0,
                 command_timeout=10.0, retry_interval=0.05):
        deadline = time.monotonic() + timeout
        last_error = None
        while time.monotonic() < deadline:
            try:
                self.socket = socket.create_connection(
                    (host, port), timeout=min(0.25, command_timeout))
                break
            except OSError as exc:
                last_error = exc
                time.sleep(retry_interval)
        else:
            raise TimeoutError(f"cannot connect to ZRCP at {host}:{port}: {last_error}")

        self.socket.settimeout(command_timeout)
        try:
            self._read_prompt()
        except Exception:
            self.socket.close()
            raise

    def _read_prompt(self):
        response = bytearray()
        while not response.endswith(b"> "):
            part = self.socket.recv(1 << 20)
            if not part:
                raise ConnectionError("ZRCP closed before sending its prompt")
            response.extend(part)

    def command(self, text):
        self.socket.sendall((text + "\n").encode())
        response = bytearray()
        while True:
            try:
                part = self.socket.recv(1 << 20)
            except socket.timeout:
                break
            if not part:
                break
            response.extend(part)
            if response.endswith(b"> "):
                break
        return response.decode("latin1", "replace")

    def read_memory(self, address, length):
        response = self.command(f"read-memory {address} {length}")
        hex_lines = []
        for line in response.splitlines():
            line = line.strip()
            if not line or line.startswith("command"):
                continue
            if line.startswith(("Welcome", "Write", "Returns", "Dumps")):
                continue
            hex_lines.append(line)
        hex_data = "".join(hex_lines)
        hex_data = "".join(c for c in hex_data if c in "0123456789abcdefABCDEF")
        return bytes.fromhex(hex_data[:length * 2]) if hex_data else b""

    def write_memory(self, address, value):
        return self.command(f"write-memory {address} {value}")

    def write_port(self, address, value):
        return self.command(f"write-port {address} {value}")

    def set_register(self, assignment):
        return self.command(f"set-register {assignment}")

    def load_binary(self, path, address, length=None):
        if length is None:
            length = os.path.getsize(path)
        return self.command(
            f"load-binary {_quote_argument(path)} {address} {length}")

    def run_cycles(self, cycles):
        return self.command(f"run {cycles}")

    def get_partial_tstates(self):
        response = self.command("get-tstates-partial").partition("\n")[0].strip()
        if not response.isdecimal():
            raise RuntimeError(f"cannot read the partial T-state counter: {response!r}")
        return int(response)

    def enter_cpu_step(self):
        return self.command("enter-cpu-step")

    def exit_cpu_step(self):
        return self.command("exit-cpu-step")

    def save_screen(self, path):
        path = os.path.abspath(path)
        if os.path.splitext(path)[1].lower() != ".png":
            return self.command(f"save-screen {_quote_argument(path)}")

        temporary_bmp = path + ".capture.bmp"
        try:
            response = self.command(
                f"save-screen {_quote_argument(temporary_bmp)}")
            bmp_to_png(temporary_bmp, path)
            return response
        finally:
            try:
                os.unlink(temporary_bmp)
            except FileNotFoundError:
                pass

    def close(self):
        try:
            self.socket.close()
        except OSError:
            pass


class ZesaruxRunner:
    """Own a ZEsarUX process and expose its ZRCP client."""

    def __init__(self, executable, machine="48K", port=10040,
                 video_output="null", audio_output="null", zoom=1,
                 extra_args=(), log_path=None, connect_timeout=30.0,
                 quickexit=True):
        self.executable = os.fspath(executable)
        self.machine = machine
        self.port = port
        self.video_output = video_output
        self.audio_output = audio_output
        self.zoom = zoom
        self.extra_args = list(extra_args)
        self.log_path = log_path
        self.connect_timeout = connect_timeout
        self.quickexit = quickexit
        self.process = None
        self.remote = None
        self._log = None

    def start(self):
        if self.process is not None:
            raise RuntimeError("ZEsarUX runner has already been started")

        stdout = None
        if self.log_path:
            os.makedirs(os.path.dirname(os.path.abspath(self.log_path)), exist_ok=True)
            self._log = open(self.log_path, "wb")
            stdout = self._log

        command = [
            self.executable,
            "--noconfigfile",
            "--machine", self.machine,
            "--vo", self.video_output,
            "--ao", self.audio_output,
            "--zoom", str(self.zoom),
            "--enable-remoteprotocol",
            "--remoteprotocol-port", str(self.port),
            *self.extra_args,
        ]
        if self.quickexit:
            command.append("--quickexit")
        try:
            self.process = subprocess.Popen(command, stdout=stdout,
                                            stderr=subprocess.STDOUT)
            self.remote = ZrcpClient(self.port, timeout=self.connect_timeout)
        except Exception:
            self.close()
            raise
        return self

    def close(self):
        if self.remote is not None:
            self.remote.close()
            self.remote = None
        if self.process is not None:
            if self.process.poll() is None:
                self.process.terminate()
            try:
                self.process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait()
            self.process = None
        if self._log is not None:
            self._log.close()
            self._log = None

    def shutdown(self, timeout=5):
        """Ask ZEsarUX to exit cleanly, then reap it so output files flush."""
        if self.remote is not None:
            try:
                self.remote.command("exit-emulator")
            except (OSError, ConnectionError):
                pass
        if self.process is not None:
            try:
                self.process.wait(timeout=timeout)
            except subprocess.TimeoutExpired:
                self.close()
                return
        self.close()

    def detach(self):
        """Close the remote connection but leave the emulator process running."""
        if self.remote is not None:
            self.remote.close()
            self.remote = None
        self.process = None
        if self._log is not None:
            self._log.close()
            self._log = None

    def __enter__(self):
        return self.start()

    def __exit__(self, exc_type, exc_value, traceback):
        self.close()


# ZX keyboard matrix: key name -> (row, bit) pairs, bit 0 means pressed.
ZX_KEYS = {
    "up": [(4, 3)],
    "down": [(4, 4)],
    "enter": [(6, 0)],
    "space": [(7, 0)],
    "y": [(5, 4)],
    "n": [(7, 3)],
    "1": [(3, 0)],
    "2": [(3, 1)],
    "3": [(3, 2)],
    "4": [(3, 3)],
    "break": [(0, 0), (7, 0)],
}


def keyboard_matrix(pressed):
    """Format a key list for ZRCP's set-ui-io-ports command."""
    rows = [0xFF] * 8
    for row, bit in pressed:
        rows[row] &= ~(1 << bit)
    return "".join(f"{value:02X}" for value in rows) + "00"


def apply_keys(remote, script):
    """Inject semicolon-separated key presses and cycle waits through ZRCP."""
    idle = keyboard_matrix([])
    for step in (part.strip() for part in script.split(";")):
        if not step:
            continue
        if step.lower().startswith("w") and step[1:].isdigit():
            remote.run_cycles(max(1, int(step[1:])) * 500000)
            continue
        key_name, _, hold = step.partition("~")
        keys = ZX_KEYS.get(key_name.lower())
        if keys is None:
            raise ValueError(f"unknown key in --keys script: {step}")
        remote.command(f"set-ui-io-ports {keyboard_matrix(keys)}")
        remote.run_cycles(max(1, int(hold) if hold else 1) * 500000)
        remote.command(f"set-ui-io-ports {idle}")
        remote.run_cycles(120000)


def drive_menu(remote, script, shot_dir=None):
    """Drive a ZX menu using semicolon-separated keys and cycle waits."""
    def shot(index, step):
        if not shot_dir:
            return
        os.makedirs(shot_dir, exist_ok=True)
        path = os.path.join(shot_dir, f"{index:02d}_{step}.bmp")
        remote.save_screen(path)
        print(f"menu shot: {path}")

    idle = keyboard_matrix([])
    for index, step in enumerate(item.strip() for item in script.split(";")):
        if not step:
            continue
        if step.lower().startswith("w") and step[1:].isdigit():
            for _ in range(int(step[1:])):
                remote.run_cycles(500000)
        else:
            name, _, hold = step.partition("~")
            keys = ZX_KEYS.get(name.lower())
            if keys is None:
                raise ValueError(f"unknown key in menu script: {step}")
            remote.command(f"set-ui-io-ports {keyboard_matrix(keys)}")
            for _ in range(int(hold) if hold else 1):
                remote.run_cycles(500000)
            remote.command(f"set-ui-io-ports {idle}")
            remote.run_cycles(200000)
            print(f"menu key: {step}")
        shot(index, step)
