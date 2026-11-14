# mhmt

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

Здесь находятся неизменённые исходники хостового упаковщика MeHruMsT (`mhmt`) авторства lvd^nedopc.
Та же версия исходников распространяется в NedooS с [лицензией GPLv3](LICENSE); лицензия сохранена
рядом с копией.

Для сборки выполните `make -C tools/mhmt`. Результат — `tools/mhmt/build/mhmt`. Сборка appmake в SDK
также автоматически собирает этот исполняемый файл. Appmake вызывает его отдельным процессом для
сжатия SPG в MegaLZ/Hrust; программы не линкуются друг с другом. Другие хостовые инструменты могут
вызывать `mhmt` или использовать его цель Make.

Параметры SPG описаны в [документации appmake](../appmake/README.ru.md).
