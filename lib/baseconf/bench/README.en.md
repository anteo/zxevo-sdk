# Font draw benchmarks

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

Run `make -C lib/baseconf/bench` for ZX256 or `make -C lib/baseconf/bench BENCH_MODE=4` for ATM640.
The harness measures ZEsarUX's partial Z80 T-state counter between start/end breakpoints.

The benchmark draws 64 opaque `p` glyphs through each font descriptor callback. In ZX256, the 5×8
positions cycle through x=0, 6, 12, and 18, exercising four bit offsets within a byte. ZX256
measures font5 and font8 and writes `lib/baseconf/bench/build/font-draw-bench-0-results.json`.
ATM640 measures font5 and writes `lib/baseconf/bench/build/font-draw-bench-4-results.json`. Use
`ZESARUX=/path/to/zesarux` to select the emulator. Building the TAP requires the SDK appmake.
[Appmake prerequisites](../../../tools/appmake/README.en.md)

### Historical measurements

The C baseline and Z80 kernel used the same ZX256 callback workload. The current benchmark measures
whichever renderer is linked into the library.

| Renderer         | T-states / 64 glyphs | T-states / glyph |
| ---------------- | -------------------: | ---------------: |
| font5 C baseline |            1,338,989 |         20,921.7 |
| font5 Z80 kernel |              357,309 |          5,583.0 |
| font8 C baseline |              734,445 |         11,475.7 |
| font8 Z80 kernel |              618,797 |          9,668.7 |

The ZX256 font5 path is about 3.75× faster and font8 about 1.19× faster with the Z80 kernels.

The historical ATM640 font5 measurement was 2,304,066 T-states (36,001 per glyph).
