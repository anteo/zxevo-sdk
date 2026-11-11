# Common library tests

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

Run the same audio, mouse, Z80 IRQ, Nemo IDE, UART, ZX attribute, SD card data, AVR version record
and RAM pool/heap cases on BaseConf and TSConf.

```sh
make -C lib/common/tests test
python3 lib/common/tests/run.py check --case interrupt/interrupt_z80
```

Each case has one C entry point under `cases/`. The common runner uses the existing machine adapters
and their profiles. A case can override metadata by machine in the optional `targets.baseconf` and
`targets.tsconf` JSON entries. The memory and interrupt cases select their hardware setup in the
case source. The UART case checks arguments on both machines. Host PTY exchange uses the BaseConf
emulator bridge for the Kondratyev UART.

The runner stores binaries and manifests in `build/baseconf` and `build/tsconf` and results in
`out/baseconf` and `out/tsconf`. Console output labels each case by machine, for example
`BaseConf/audio` and `TSConf/audio`. The platform suites cover their own APIs, including BaseConf
NMI and execution traps.
