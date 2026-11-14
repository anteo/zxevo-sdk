# Примеры TSConf

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

- `sdk/`: демонстрационные программы zxevo-sdk — `hello.c`, `harbour.c`, `moon_run.c`.
- [evosdk/](evosdk/README.ru.md): порты демонстраций evosdk из каталога `pentevo/sdk/evosdkts`
  [репозитория TSConf](https://github.com/tslabs/zx-evo), их ресурсы и отдельная сборка ресурсов.
  [XNX](evosdk/xnx/README.ru.md) — полный игровой пример с самостоятельным SPG-запуском.

Сборка из корня репозитория:

```sh
make examples-tsconf
make examples-evosdk
```

[Инструменты ресурсов](../../../tools/assets/README.ru.md) автоматически готовят зависимости Python.
TAP демонстраций zxevo-sdk сохраняются в `lib/tsconf/build/examples/`, порты evosdk — в
`lib/tsconf/examples/evosdk/build/zx0/<пример>/demo.tap`.
