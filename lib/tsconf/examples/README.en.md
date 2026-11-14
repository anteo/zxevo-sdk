# TSConf examples

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

- `sdk/`: zxevo-sdk demonstration programs — `hello.c`, `harbour.c`, `moon_run.c`.
- [evosdk/](evosdk/README.en.md): ports of evosdk demonstrations from `pentevo/sdk/evosdkts` in the
  [TSConf repository](https://github.com/tslabs/zx-evo), with their assets and a separate resource
  build. [XNX](evosdk/xnx/README.en.md) is the complete game example with standalone SPG startup.

Build from the repository root:

```sh
make examples-tsconf
make examples-evosdk
```

The [asset tools](../../../tools/assets/README.en.md) prepare Python dependencies automatically. SDK
TAPs are written to `lib/tsconf/build/examples/`; the evosdk TAPs go to
`lib/tsconf/examples/evosdk/build/zx0/<example>/demo.tap`.
