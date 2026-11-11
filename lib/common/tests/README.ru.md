# Тесты общего кода

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

Одни и те же кейсы проверяют звук, мышь, прерывания Z80, Nemo IDE, UART, ZX-атрибуты, данные
SD-карты, запись версии AVR, пул страниц RAM и страничную кучу в BaseConf и TSConf.

```sh
make -C lib/common/tests test
python3 lib/common/tests/run.py check --case interrupt/interrupt_z80
```

У каждого кейса один C-файл с точкой входа в `cases/`. Раннер использует адаптеры и профили обеих
конфигураций. Поля `targets.baseconf` и `targets.tsconf` в JSON позволяют переопределить метаданные
для одной машины. Кейсы памяти и прерываний выбирают аппаратную настройку в исходнике. Тест UART
проверяет аргументы на обеих машинах. Обмен через псевдотерминал проверяется в BaseConf на сборке
ZEsarUX с мостом для UART Кондратьева.

Бинарники и манифесты сохраняются в `build/baseconf` и `build/tsconf`, результаты в `out/baseconf` и
`out/tsconf`. В выводе имя машины указывается перед именем кейса, например `BaseConf/audio` и
`TSConf/audio`. Специфичные для платформы проверки, в том числе NMI и ловушки исполнения BaseConf,
находятся в отдельных наборах. [Раннер и ZXHost](../../../tools/test_runner/README.ru.md)
