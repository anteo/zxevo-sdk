#!/usr/bin/env python3
"""Render a z88dk .map file as memory areas, modules and function ranges."""

from __future__ import annotations

import argparse
import re
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path


AREA_RE = re.compile(
    r"^__(code|rodata|data|bss)_(.+)_(head|size|tail)\s*=\s*\$([0-9A-Fa-f]+)"
)
SYMBOL_RE = re.compile(
    r"^\s*(\S+)\s*=\s*\$([0-9A-Fa-f]+)\s*;\s*addr,\s*"
    r"(public|local),\s*,\s*([^,]*),\s*([^,]*),\s*(.*)$"
)


@dataclass
class Area:
    kind: str
    name: str
    head: int | None = None
    size: int | None = None
    tail: int | None = None


@dataclass
class Symbol:
    name: str
    address: int
    scope: str
    module: str
    section: str
    source: str
    end: int = 0


def parse_map(path: Path) -> tuple[list[Area], list[Symbol]]:
    areas_by_key: dict[tuple[str, str], Area] = {}
    symbols: list[Symbol] = []

    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        area_match = AREA_RE.match(line)
        if area_match:
            kind, name, field, raw_value = area_match.groups()
            area = areas_by_key.setdefault((kind, name), Area(kind, name))
            setattr(area, field, int(raw_value, 16))
            continue

        symbol_match = SYMBOL_RE.match(line)
        if symbol_match:
            name, raw_address, scope, module, section, source = symbol_match.groups()
            if section.startswith("code_"):
                symbols.append(
                    Symbol(
                        name=name,
                        address=int(raw_address, 16),
                        scope=scope,
                        module=module.strip(),
                        section=section.strip(),
                        source=source.strip(),
                    )
                )

    areas = sorted(
        areas_by_key.values(),
        key=lambda area: (area.kind, area.head if area.head is not None else -1, area.name),
    )
    return areas, symbols


def is_function_entry(symbol: Symbol) -> bool:
    """Recognize public entries and static C functions in compiler code."""
    if symbol.scope == "public":
        return True
    # SDCC emits _function for static C functions and l_function_00102
    # for branches within functions.
    return symbol.section == "code_compiler" and re.fullmatch(r"_[A-Za-z_]\w*", symbol.name) is not None


def size_function_ranges(symbols: list[Symbol], areas: list[Area]) -> list[Symbol]:
    section_bounds = {
        f"{area.kind}_{area.name}": (area.head, area.tail)
        for area in areas
        if area.kind == "code" and area.head is not None and area.tail is not None
    }
    entries = [
        symbol
        for symbol in symbols
        if is_function_entry(symbol)
        and symbol.section in section_bounds
        and section_bounds[symbol.section][0] <= symbol.address < section_bounds[symbol.section][1]
    ]
    by_section: dict[str, list[Symbol]] = defaultdict(list)
    for symbol in entries:
        by_section[symbol.section].append(symbol)

    for section, members in by_section.items():
        members.sort(key=lambda item: (item.address, item.module, item.name))
        section_end = section_bounds[section][1]
        for index, symbol in enumerate(members):
            next_address = next(
                (other.address for other in members[index + 1 :] if other.address > symbol.address),
                section_end,
            )
            symbol.end = max(symbol.address, next_address)
    return entries


def hex_range(start: int, end: int) -> str:
    return f"{start:04X}-{end:04X}"


def print_areas(areas: list[Area], sort_by_size: bool = False) -> None:
    print("MEMORY AREAS (end address is exclusive)")
    print(f"{'AREA':<34} {'RANGE':<11} {'SIZE':>8}")
    ordered = (
        sorted(areas, key=lambda area: (-(area.size or 0), area.name))
        if sort_by_size
        else areas
    )
    for area in ordered:
        if area.size == 0:
            continue
        start = area.head if area.head is not None else 0
        end = area.tail if area.tail is not None else start + (area.size or 0)
        name = f"{area.kind}_{area.name}"
        print(f"{name:<34} {hex_range(start, end):<11} {area.size or 0:>5} B  0x{area.size or 0:04X}")


def fit_column(value: str, width: int) -> str:
    if len(value) <= width:
        return value
    if width <= 1:
        return value[:width]
    left = (width - 1) // 2
    right = width - left - 1
    return value[:left] + "…" + value[-right:]


def print_modules(
    entries: list[Symbol], module_filter: str | None, name_width: int, sort_by_size: bool
) -> None:
    grouped: dict[tuple[str, str], list[Symbol]] = defaultdict(list)
    for symbol in entries:
        if module_filter and module_filter.lower() not in symbol.module.lower():
            continue
        grouped[(symbol.section, symbol.module or "(no module)")].append(symbol)

    print("\nCODE BY MODULE AND FUNCTION (function end is the next linked function start)")
    print(f"{'MODULE / FUNCTION':<{name_width}} {'RANGE':<11} {'SIZE':>8}  SOURCE")

    def group_size(members: list[Symbol]) -> int:
        return sum(
            end - start
            for start, end in {
                (symbol.address, symbol.end)
                for symbol in members
                if symbol.end > symbol.address
            }
        )

    def group_key(item: tuple[tuple[str, str], list[Symbol]]) -> tuple:
        key, members = item
        if sort_by_size:
            return (-group_size(members), min(s.address for s in members), key)
        return (min(s.address for s in members), key)

    for (section, module), members in sorted(grouped.items(), key=group_key):
        unique_ranges = {
            (symbol.address, symbol.end)
            for symbol in members
            if symbol.end > symbol.address
        }
        if unique_ranges:
            module_start = min(start for start, _ in unique_ranges)
            module_end = max(end for _, end in unique_ranges)
            occupied = sum(end - start for start, end in unique_ranges)
            print(
                f"{fit_column(module + ' [' + section + ']', name_width):<{name_width}} "
                f"{hex_range(module_start, module_end):<11} {occupied:>5} B  0x{occupied:04X}"
            )
        if sort_by_size:
            ordered_members = sorted(
                members, key=lambda item: (-(item.end - item.address), item.address, item.name)
            )
        else:
            ordered_members = sorted(members, key=lambda item: (item.address, item.name))
        for symbol in ordered_members:
            size = symbol.end - symbol.address
            source = symbol.source or "-"
            print(
                f"  {fit_column(symbol.name, name_width - 2):<{name_width - 2}} "
                f"{hex_range(symbol.address, symbol.end):<11} "
                f"{size:>5} B  0x{size:04X}  {source}"
            )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Show z88dk linker map memory use by area, module and function."
    )
    parser.add_argument("map", type=Path, help="path to the linker .map file")
    parser.add_argument(
        "--module", help="show only modules whose names contain this text (case-insensitive)"
    )
    parser.add_argument(
        "--name-width",
        type=int,
        default=48,
        help="maximum width of the module/function name column (default: 48)",
    )
    parser.add_argument(
        "--sort",
        choices=("address", "size"),
        default="address",
        help="sort modules and functions by address (default) or descending size",
    )
    args = parser.parse_args()

    if args.name_width < 12:
        parser.error("--name-width must be at least 12")

    if not args.map.is_file():
        parser.error(f"map file not found: {args.map}")
    areas, symbols = parse_map(args.map)
    if not areas and not symbols:
        print(f"No z88dk memory areas or code symbols found in {args.map}", file=sys.stderr)
        return 1
    entries = size_function_ranges(symbols, areas)
    sort_by_size = args.sort == "size"
    print_areas(areas, sort_by_size)
    print_modules(entries, args.module, args.name_width, sort_by_size)
    print("\nNote: function ranges are inferred from linker-visible function starts;")
    print("      internal branch labels and anonymous bytes are not listed separately.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
