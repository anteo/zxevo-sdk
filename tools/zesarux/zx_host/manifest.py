"""Typed model and JSON serialization for ZXHost program manifests."""
from dataclasses import dataclass, field
import json
from typing import Optional


@dataclass(frozen=True)
class LaunchConfig:
    boot_cycles: int
    ports: tuple

    def to_dict(self):
        return {
            "boot_cycles": self.boot_cycles,
            "ports": [list(port_write) for port_write in self.ports],
        }


@dataclass(frozen=True)
class BlockRecord:
    name: str
    address: int
    physical_page: int
    window: int
    port: int
    raw_page: int
    category: Optional[str]
    filename: str
    length: int

    def to_dict(self):
        return {
            "name": self.name,
            "address": self.address,
            "physical_page": self.physical_page,
            "window": self.window,
            "port": self.port,
            "raw_page": self.raw_page,
            "category": self.category,
            "filename": self.filename,
            "length": self.length,
        }


@dataclass(frozen=True)
class ProgramManifest:
    protocol: dict
    machine: str
    launch: LaunchConfig
    entry: int
    stack: int
    blocks: tuple

    def to_dict(self):
        return {
            "protocol": self.protocol,
            "machine": self.machine,
            "launch": self.launch.to_dict(),
            "entry": self.entry,
            "stack": self.stack,
            "blocks": [block.to_dict() for block in self.blocks],
        }

    def write_json(self, path):
        with open(path, "w", encoding="utf-8") as stream:
            json.dump(self.to_dict(), stream, indent=2)
            stream.write("\n")


@dataclass
class ZXHostManifestBuilder:
    protocol: dict
    machine: str
    launch: LaunchConfig
    entry: int
    stack: int
    blocks: list = field(default_factory=list)

    def add_block(self, block):
        if not isinstance(block, BlockRecord):
            raise TypeError("manifest blocks must be BlockRecord values")
        self.blocks.append(block)
        return self

    def build(self):
        return ProgramManifest(
            protocol=self.protocol,
            machine=self.machine,
            launch=self.launch,
            entry=self.entry,
            stack=self.stack,
            blocks=tuple(self.blocks),
        )
