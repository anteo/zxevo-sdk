"""Host-side codec for the memory mailbox published by ZXHost programs."""
import json


class ZXHostProtocol:
    def __init__(self, descriptor):
        self.descriptor = descriptor
        self.fields = descriptor["fields"]
        self.states = descriptor["states"]
        self._validate_descriptor()

    def _validate_descriptor(self):
        required_fields = {
            "magic", "version", "state", "cancel", "flags", "command",
            "arg0", "arg1", "result0", "result1", "result2", "result3",
            "sequence",
        }
        missing = required_fields.difference(self.fields)
        if missing:
            raise ValueError(f"ZXHost protocol is missing fields: {', '.join(sorted(missing))}")
        required_states = {"idle", "done", "aborted", "error"}
        missing = required_states.difference(self.states)
        if missing:
            raise ValueError(f"ZXHost protocol is missing states: {', '.join(sorted(missing))}")
        header_address = self.descriptor["header_address"]
        header_size = self.descriptor["header_size"]
        magic = self.descriptor["magic"].encode("ascii")
        if len(magic) != 4 or not 1 <= self.descriptor["version"] <= 0xFF:
            raise ValueError("ZXHost magic must be four ASCII bytes and version must fit in a byte")
        if not 0 <= header_address <= 0xFFFF or not 16 <= header_size <= 0x10000-header_address:
            raise ValueError("ZXHost header address/size is outside the 16-bit address space")
        offsets = list(self.fields.values())
        if any(not isinstance(offset, int) or not 0 <= offset < header_size for offset in offsets):
            raise ValueError("ZXHost field offset is outside the declared header")
        if len(set(offsets)) != len(offsets):
            raise ValueError("ZXHost header fields must use distinct byte offsets")
        state_values = list(self.states.values())
        if any(not isinstance(state, int) or not 0 <= state <= 0xFF for state in state_values):
            raise ValueError("ZXHost state values must fit in one byte")
        if len(set(state_values)) != len(state_values):
            raise ValueError("ZXHost states must use distinct byte values")
        log_address = self.descriptor["log_address"]
        log_size = self.descriptor["log_size"]
        if not 0 <= log_address <= 0xFFFF or not 1 <= log_size <= 0x10000-log_address:
            raise ValueError("ZXHost log address/size is outside the 16-bit address space")
        if (header_address < log_address + log_size and
                log_address < header_address + header_size):
            raise ValueError("ZXHost mailbox and log regions must not overlap")
        if self.descriptor.get("log_format") != "nul-terminated":
            raise ValueError("unsupported ZXHost log format")

    @classmethod
    def from_file(cls, path):
        with open(path, "r", encoding="utf-8") as stream:
            return cls(json.load(stream))

    @classmethod
    def from_manifest(cls, manifest):
        if "protocol" not in manifest:
            raise ValueError("program manifest has no ZXHost protocol descriptor")
        return cls(manifest["protocol"])

    def _at(self, field):
        return self.descriptor["header_address"] + self.fields[field]

    @staticmethod
    def validate_request(command, args, sequence):
        if len(args) != 2:
            raise ValueError("ZXHost requests contain exactly two argument bytes")
        values = (command, args[0], args[1], sequence)
        if any(not isinstance(value, int) or not 0 <= value <= 0xFF for value in values):
            raise ValueError("ZXHost command, arguments and sequence must be bytes")

    def prepare_request(self, remote, command, args=(0, 0), sequence=1):
        self.validate_request(command, args, sequence)
        # Clear completion/cancel before publishing the request. Sequence is
        # written last and identifies the result expected from this session.
        remote.write_memory(hex(self._at("state")), "0")
        remote.write_memory(hex(self._at("cancel")), "0")
        remote.write_memory(hex(self._at("command")), f"0x{command:02X}")
        remote.write_memory(hex(self._at("arg0")), f"0x{args[0]:02X}")
        remote.write_memory(hex(self._at("arg1")), f"0x{args[1]:02X}")
        remote.write_memory(hex(self._at("sequence")), f"0x{sequence:02X}")

    def request_cancel(self, remote):
        remote.write_memory(hex(self._at("cancel")), "0x01")

    def read_header(self, remote):
        return remote.read_memory(self.descriptor["header_address"],
                                  self.descriptor["header_size"])

    def is_valid(self, header):
        magic = self.descriptor["magic"].encode("ascii")
        version = self.descriptor["version"]
        start = self.fields["magic"]
        return (len(header) >= self.descriptor["header_size"] and
                header[start:start+4] == magic and
                header[self.fields["version"]] == version)

    def state(self, header):
        if not self.is_valid(header):
            return None
        return header[self.fields["state"]]

    def is_complete(self, header):
        return self.state(header) in {
            self.states["done"], self.states["aborted"], self.states["error"]
        }

    def read_log(self, remote):
        raw = remote.read_memory(self.descriptor["log_address"],
                                 self.descriptor["log_size"])
        return raw.split(b"\x00", 1)[0].decode("latin1", "replace")

    def decode_result(self, header, log=""):
        if not self.is_valid(header):
            raise ValueError("invalid ZXHost result header")
        state = header[self.fields["state"]]
        if state not in self.states.values():
            raise ValueError(f"unknown ZXHost state byte: {state}")
        if state == self.states["idle"]:
            raise ValueError("ZXHost result header is still idle")
        return {
            "magic": self.descriptor["magic"],
            "version": self.descriptor["version"],
            "state": state,
            "cancel": header[self.fields["cancel"]],
            "flags": header[self.fields["flags"]],
            "sequence": header[self.fields["sequence"]],
            "command": header[self.fields["command"]],
            "args": (header[self.fields["arg0"]], header[self.fields["arg1"]]),
            "results": tuple(header[self.fields["result%d" % n]] for n in range(4)),
            "log": log,
        }
