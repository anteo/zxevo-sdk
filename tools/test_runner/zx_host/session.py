"""Host-side sessions with ZXHost runtimes running on the emulated ZX."""
import json
import os
import time

from tools.zesarux.runner import ZesaruxRunner

from .protocol import ZXHostProtocol


class ZXHostSession:
    """Talk to a ZXHost target; ZesaruxRunner supplies emulator transport."""

    def __init__(self, manifest_path, zesarux, machine=None, port=10040,
                 video_output="null", audio_output="null", zoom=1,
                 extra_args=("--hardware-debug-ports",), log_path=None,
                 connect_timeout=30.0, quickexit=True):
        self.manifest_path = os.path.abspath(os.fspath(manifest_path))
        self.base_dir = os.path.dirname(self.manifest_path)
        with open(self.manifest_path, "r", encoding="utf-8") as stream:
            self.manifest = json.load(stream)
        self.protocol = ZXHostProtocol.from_manifest(self.manifest)
        self.runtime_memory = self.manifest.get("runtime_memory")
        self._validate_runtime_memory()
        self.runner = ZesaruxRunner(
            zesarux, machine=machine or self.manifest.get("machine", "48K"),
            port=port, video_output=video_output, audio_output=audio_output,
            zoom=zoom, extra_args=extra_args, log_path=log_path,
            connect_timeout=connect_timeout, quickexit=quickexit)
        self.remote = None
        self.sequence = 0

    def _validate_runtime_memory(self):
        """Check the package's documented bootstrap-to-runtime mailbox mapping."""
        memory = self.runtime_memory
        if memory is None:
            return
        window = memory.get("resident_window")
        bootstrap_page = memory.get("bootstrap_page")
        runtime_page = memory.get("runtime_page")
        transfer_offset = memory.get("transfer_source_offset")
        transfer_length = memory.get("transfer_length")
        if (not isinstance(window, int) or not 0 <= window <= 3 or
                not isinstance(bootstrap_page, int) or not 0 <= bootstrap_page <= 0xFF or
                not isinstance(runtime_page, int) or not 0 <= runtime_page <= 0xFF or
                not isinstance(transfer_offset, int) or not 0 <= transfer_offset < 0x4000 or
                not isinstance(transfer_length, int) or
                not 1 <= transfer_length <= 0x4000 - transfer_offset):
            raise ValueError("manifest runtime_memory mapping is invalid")
        window_start = window * 0x4000
        window_end = window_start + 0x4000
        for key, size in (("mailbox_address", self.protocol.descriptor["header_size"]),
                          ("log_address", self.protocol.descriptor["log_size"])):
            address = memory.get(key)
            if (not isinstance(address, int) or address < window_start or
                    address + size > window_end):
                raise ValueError(f"manifest {key} is outside the resident CPU window")
            offset = address - window_start
            if not transfer_offset <= offset or offset + size > transfer_offset + transfer_length:
                raise ValueError(f"manifest {key} is outside the mailbox transfer range")
        if memory["mailbox_address"] != self.protocol.descriptor["header_address"] or \
                memory["log_address"] != self.protocol.descriptor["log_address"]:
            raise ValueError("manifest runtime_memory addresses disagree with ZXHost protocol")
        if not any(block.get("window") == window and
                   block.get("physical_page") == bootstrap_page
                   for block in self.manifest.get("blocks", [])):
            raise ValueError("manifest has no bootstrap block on the mailbox source page")

    def start(self, command, args=(0, 0), *, prepare=None):
        """Boot, optionally prepare the machine, load the blocks and set PC."""
        if self.remote is not None:
            raise RuntimeError("ZXHost session has already started")
        next_sequence = (self.sequence + 1) & 0xFF
        self.protocol.validate_request(command, args, next_sequence)
        try:
            self.runner.start()
            self.remote = self.runner.remote
            self.remote.enter_cpu_step()
            launch = self.manifest.get("launch", {})
            self.remote.run_cycles(launch.get("boot_cycles", 0))
            if prepare is not None:
                prepare(self.remote)
            for address, value in launch.get("ports", []):
                self.remote.write_port(hex(address), hex(value))
            for block in self.manifest["blocks"]:
                binary = os.path.join(self.base_dir, block["filename"])
                if not os.path.isfile(binary):
                    raise ValueError(f"manifest block file is missing: {binary}")
                if os.path.getsize(binary) != block["length"]:
                    raise ValueError(f"manifest length does not match block file: {binary}")
                self.remote.write_port(hex(block["port"]), str(block["raw_page"]))
                self.remote.load_binary(binary, block["address"], block["length"])
            self.sequence = next_sequence
            # A target with runtime_memory starts with this request on its
            # bootstrap page and is responsible for moving it before use.
            self.protocol.prepare_request(self.remote, command, args, self.sequence)
            self.remote.set_register(f"SP={self.manifest['stack']:04X}H")
            self.remote.set_register(f"PC={self.manifest['entry']:04X}H")
        except Exception:
            self.close()
            raise
        return self

    def run_cycles(self, cycles):
        self._require_running()
        return self.remote.run_cycles(cycles)

    def wait_for_completion(self, timeout=15.0, poll_cycles=200000):
        self._require_running()
        if timeout <= 0 or poll_cycles <= 0:
            raise ValueError("timeout and poll_cycles must be positive")
        deadline = time.monotonic() + timeout
        header = b""
        while time.monotonic() < deadline:
            self.remote.run_cycles(poll_cycles)
            header = self.protocol.read_header(self.remote)
            if (self.protocol.is_complete(header) and
                    header[self.protocol.fields["sequence"]] == self.sequence):
                return self.protocol.decode_result(
                    header, self.protocol.read_log(self.remote))
        registers = self.remote.command("get-registers").strip()
        raise TimeoutError(f"ZXHost did not complete before timeout; CPU {registers}")

    def request_cancel(self):
        self._require_running()
        self.protocol.request_cancel(self.remote)

    def capture(self, path):
        self._require_running()
        return self.remote.save_screen(path)

    def _require_running(self):
        if self.remote is None:
            raise RuntimeError("ZXHost session has not started")

    def exit_cpu_step(self):
        if self.remote is not None:
            return self.remote.exit_cpu_step()

    def close(self):
        self.runner.close()
        self.remote = None

    def shutdown(self):
        self.runner.shutdown()
        self.remote = None

    def detach(self):
        self.runner.detach()
        self.remote = None

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.close()
