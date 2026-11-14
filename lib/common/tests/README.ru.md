# Тесты общего кода

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

Одни и те же кейсы проверяют звук, мышь, прерывания Z80, Nemo IDE, UART, ZX-атрибуты, данные
SD-карты, запись версии AVR, пул страниц RAM и страничную кучу в BaseConf и TSConf.

```sh
make -C lib/common/tests test
python3 tools/test_runner/runner.py common check --case interrupt/interrupt_z80
```

У каждого кейса один C-файл с точкой входа в `cases/`. Раннер использует адаптеры и профили обеих
конфигураций. Таблицы `targets.baseconf` и `targets.tsconf` в TOML позволяют переопределить метаданные
для одной машины. Кейсы памяти и прерываний выбирают аппаратную настройку в исходнике. Тест UART
проверяет аргументы на обеих машинах. Обмен через псевдотерминал проверяется в BaseConf на сборке
ZEsarUX с мостом для UART Кондратьева.

Бинарники, манифесты и результаты сохраняются в `build/<машина>/<путь-кейса>/<профиль>/`.
Каталоги машин называются `baseconf` и `tsconf`.
Общие эталоны лежат в `cases/<путь-кейса>/`, отличия — в
`cases/<путь-кейса>/<машина>/<профиль>/`. В выводе имя машины указывается перед именем кейса,
например `BaseConf/audio` и `TSConf/audio`. Специфичные для платформы проверки, в том числе NMI
и ловушки исполнения BaseConf, находятся в отдельных наборах. [Раннер и ZXHost](../../../tools/test_runner/README.ru.md)
