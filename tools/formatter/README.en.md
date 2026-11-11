# Source formatters

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

Four small programs, one job each:

| Program      | Job                              | Own options                            |
| ------------ | -------------------------------- | -------------------------------------- |
| `formatter`  | Dispatches by file extension     | `--EXT-formatter=PROGRAM`, `-h`        |
| `format_asm` | Assembly via `awk`               | `--dialect`, `--check`                 |
| `format_c`   | C and headers via `clang-format` | `--clang-format`, `--style`, `--check` |
| `format_md`  | Markdown via Prettier            | `--prettier`, `--config`, `--check`    |

```sh
tools/formatter/formatter --dialect=z80asm lib/common/src/color/z80 lib/common/include/zx README.md
tools/formatter/formatter --check lib/common/include/zx
tools/formatter/format_asm --dialect z80asm lib/common/src/color/z80
tools/formatter/format_c --clang-format /opt/bin/clang-format examples
tools/formatter/format_md README.md README.ru.md
```

## formatter: routing and proxying

`formatter` knows nothing about languages or tools, only extensions and programs. Built-in mapping:
`*.c` and `*.h` go to `format_c`, `*.md` goes to `format_md`, and other files go to `format_asm`.
Built-in helpers are looked up next to `formatter` first, then on `PATH`. `--EXT-formatter=PROGRAM`
replaces a mapping for any suffix, for example `--inc-formatter=format_asm`.

Any argument the dispatcher does not use itself is forwarded unchanged to every formatter run it
launches, and files are passed after `--`. Because the dispatcher does not know which options take a
value, forwarded options must be self-contained: write `--dialect=z80asm`, not `--dialect z80asm`.

Exit status is the worst status of the runs it launched: `0` success, `1` from `--check` with files
to reformat, `2` usage or formatter error.

## Helpers

Helpers accept an explicit file list or directories (`format_asm` expands `*.asm`, `format_c`
expands `*.c` and `*.h`, `format_md` expands `*.md`) and process explicit files whatever their
extension. Files are rewritten only when the formatted content differs, and content is written only
after the formatter succeeded, so a failing run never leaves a truncated file.

`format_asm --dialect NAME` selects `NAME.awk` (`sjasm` or `z80asm`); the default comes from
`$FORMAT_ASM_DIALECT`. `format_c --clang-format PATH` selects the executable (default
`$CLANG_FORMAT`, then `clang-format`), and `--style PATH` replaces the bundled
`z88dk-c.clang-format`. Each helper lists the options it accepts with `--options`, which is how the
dispatcher routes forwarded arguments; the environment variables are only the defaults for running a
helper directly.

`format_md --prettier PATH` selects Prettier (default `$PRETTIER`, then `prettier`), and
`--config PATH` replaces the bundled `tools/formatter/.prettierrc.json`. The bundled config wraps
prose at 100 columns. Prettier aligns table columns and keeps each row on one source line, even when
a table exceeds that width.

Rules:

- **sjasm** aligns statements and constants and normalizes hex literals for SjASMPlus: instructions
  and directives get one 8-space indent, labels and `EQU`/`EVAL` constants go to the left margin
  with aligned values, `#hex` becomes `0xhex`.
- **z80asm** only normalizes leading indentation and blank lines. Operands, `00BFh` literals, local
  `@labels`, `AF'`, quoted semicolons, expressions and the spacing before comments survive byte for
  byte.
- **z88dk-c** sets 4-space indent, attached braces, right pointer alignment, a 100-column limit,
  preserved `#include` order and comment text, and declares `__z88dk_fastcall` as an attribute
  macro. The style always comes from this directory, so the result never depends on the caller's
  directory. Editors can reuse it with
  `clang-format --style=file:tools/formatter/z88dk-c.clang-format`.

## Makefile use

Projects include the shared fragment instead of repeating the commands:

```make
FORMAT_FILES   := $(wildcard src/*.c src/*.h src/*.asm)
FORMATTER_ARGS := --dialect=z80asm   # optional, forwarded by option name

include ../tools/formatter/formatter.mk   # keep this last
```

Set `FORMAT_SUBDIRS` when a Makefile also delegates formatting to component directories. Each
component uses its own files and dialect. An empty local list is valid, so a component with no
supported sources can still expose the `format` target.

The list is never split by language: the dispatcher routes per file and finds
`format_c`/`format_asm` next to itself, so the fragment adds no paths or defaults of its own.
`FORMATTER_ARGS` carries the dispatcher options and is empty by default; each one reaches only the
formatters that declare it, so `--dialect=z80asm` never confuses `format_c`. The fragment also
restores the project's default goal, so a bare `make` still builds. `make CLANG_FORMAT=/path format`
keeps working because make exports command-line variables, and a project that pins the binary can
pass `--clang-format=$(CLANG_FORMAT)` in `FORMATTER_ARGS`.

`make format` passes `$(FORMAT_FILES)` to the dispatcher and calls `format` in `FORMAT_SUBDIRS`.

There is no per-language target: the list is one set of files, and only the dispatcher decides who
formats each file. To format a single language, call that helper directly, for example
`tools/formatter/format_c src include`.

The fragment must be included after the project's own rules: the first target of an included file
would otherwise become the default goal.

## Adding a formatter

Write a program that accepts a list of files, handles `--check`, and lists its own options with
`--options` (one name per line, without leading dashes; exit non-zero if it has no such protocol and
it will receive every forwarded argument). Map it with `--EXT-formatter=PROGRAM`. Nothing in
`formatter` or in the make fragment needs to change.
