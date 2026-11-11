# Инструменты профилирования

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

## Память

`memory.py` показывает области памяти, модули и диапазоны функций по карте линковки z88dk.
Соберите программу с флагом zcc `-m`, затем выполните команду из корня SDK.

```sh
python3 tools/profiling/memory.py path/to/program.map --sort size
```

По умолчанию отчёт отсортирован по адресам. Флаг `--module` фильтрует по имени модуля,
`--name-width` задаёт ширину колонки имён. Размер функции оценивается по следующему
символу в карте линковки. Псевдонимы могут делить один диапазон, а байты между символами
учитываются в размере этого диапазона.

## Процессор

`cpu.py` запускает TAP для BASIC 48 в отдельном процессе ZEsarUX и измеряет время функции в тактах
Z80. По умолчанию скрипт берёт `.map` рядом с TAP. Измеряемая функция должна оставаться отображённой
в память, а аргументы со стека снимает вызывающая сторона. Время выбранного вызова включает время
вложенных вызовов.

Соберите Night Train командой `make examples-baseconf` и запустите замер отрисовки из корня SDK.

```sh
python3 -m tools.profiling.cpu \
  --tap lib/baseconf/build/examples/night_train.tap --entry draw_station \
  --functions zx_draw_fill_rect zx_console_draw_op zx_console_clear
```

Флаг `--output` сохраняет замеры по вызовам в JSON. Флаги `--zesarux` и `--rom` выбирают эмулятор
и ROM. Для другой последовательности запуска BASIC передайте в `--keys` клавиши до последнего
Enter в команде `LOAD ""`. [Замеры вывода шрифтов BaseConf](../../lib/baseconf/bench/README.ru.md)
