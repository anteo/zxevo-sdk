# Profiling tools

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

## Memory

`memory.py` shows memory areas, modules, and function ranges from a z88dk linker map. Generate the
map with the zcc flag `-m`, then run from the SDK root.

```sh
python3 tools/profiling/memory.py path/to/program.map --sort size
```

The report defaults to address order. Use `--module` to filter by module name and
`--name-width` to change the name column width. Function sizes are estimates based on the
next linker-visible symbol. Aliases can share a range, and bytes between symbols count
towards the containing range.

## CPU

`cpu.py` runs a BASIC 48 TAP in an isolated ZEsarUX process and measures one Z80 function in
T-states. The linker map defaults to the `.map` next to the TAP. Choose a caller-clean function
that stays mapped throughout the measurement. The timing of a selected call includes its callees.

Build Night Train with `make examples-baseconf`, then measure its drawing routine from the SDK root.

```sh
python3 -m tools.profiling.cpu \
  --tap lib/baseconf/build/examples/night_train.tap --entry draw_station \
  --functions zx_draw_fill_rect zx_console_draw_op zx_console_clear
```

Use `--output` to save per-call timings as JSON. The `--zesarux` and `--rom` options select the
emulator and ROM. To customize BASIC startup, supply `--keys` with the keys preceding the final
Enter in `LOAD ""`. [BaseConf font benchmarks](../../lib/baseconf/bench/README.en.md)
