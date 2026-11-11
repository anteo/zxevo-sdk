# zxevo-sdk

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

Библиотеки C и Z80 ASM для приложений ZX Evolution под BaseConf и TSConf. В SDK входят конфигурации
z88dk, профиль запуска из BASIC 48, тесты в эмуляторе и инструменты для разработки.

- **BaseConf** поддерживает страничную память, видео, консоль, периферию, прямой доступ к
  накопителям и сервисы ERS. Основной заголовок — `<baseconf.h>`.
  [Документация](lib/baseconf/README.ru.md)
- **TSConf** поддерживает страничную память, видео, консоль, тайлы, спрайты, DMA, периферию, прямой
  доступ к SD и сервисы FAT из TS-BIOS. Основной заголовок — `<tsconf.h>`.
  [Документация](lib/tsconf/README.ru.md)
- **Общие API** в заголовках `zx/` покрывают графику, шрифты, форматированный вывод, страничную
  память, звук и периферию. Общий код входит в оба архива. [Документация](lib/common/README.ru.md)

## Сборка библиотек

Нужны GNU Make и z88dk с компилятором SDCC и библиотекой classic. Добавьте `zcc` и `z88dk-z80asm` в
`PATH` и укажите каталог стандартных конфигураций z88dk в `ZCCCFG`. Переменные `ZCC` и `Z80ASM`
позволяют переопределить имена исполняемых файлов.

```sh
export PATH="/path/to/z88dk/bin:$PATH"
export ZCCCFG=/path/to/z88dk/lib/config
make
```

| Цель                | Результат по умолчанию                                                 |
| ------------------- | ---------------------------------------------------------------------- |
| `make baseconf-lib` | `lib/baseconf/build/default/baseconf.lib`                              |
| `make tsconf-lib`   | `lib/tsconf/build/default/tsconf.lib` и `tsconf.cfg` в том же каталоге |

`make` собирает оба архива. В BaseConf можно отдельно выбрать реализации текстового вывода и
графических примитивов для нужных режимов. В TSConf набор режимов для консоли и рисования задаёт
`TSCONF_VIDEO_MODES`. Например, `make tsconf-lib TSCONF_VIDEO_MODES=ZX` собирает эти функции только
для ZX-режима. Остальные параметры описаны в документации библиотек.
[Параметры BaseConf](lib/baseconf/README.ru.md#размер-приложения) ·
[Параметры TSConf](lib/tsconf/README.ru.md#selecting-video-backends)

## Подключение SDK к приложению

Задайте `ZXEVO_SDK_PATH` абсолютным путём к SDK и подключите Make-фрагмент нужной конфигурации. Он
задаёт пути к заголовкам и архиву и параметры ABI classic SDCC
(`-clib=classic -compiler=sdcc --reserve-regs-iy`). Конфигурация z88dk уже указывает нужный архив.

| Конфигурация | Make-фрагмент относительно `ZXEVO_SDK_PATH` | Флаги приложения        | Флаги TAP для BASIC 48      |
| ------------ | ------------------------------------------- | ----------------------- | --------------------------- |
| BaseConf     | `lib/baseconf/baseconf.mk`                  | `$(BASECONF_APP_FLAGS)` | `$(BASECONF_BASIC48_FLAGS)` |
| TSConf       | `lib/tsconf/tsconf.mk`                      | `$(TSCONF_APP_FLAGS)`   | `$(TSCONF_BASIC48_FLAGS)`   |

Сначала соберите `tsconf.lib` командой `make -C /absolute/path/to/zxevo-sdk tsconf-lib`. Затем этот
Makefile приложения соберёт `demo.tap` из `main.c`. Запустите его командой
`make ZXEVO_SDK_PATH=/absolute/path/to/zxevo-sdk`.

```makefile
.DEFAULT_GOAL := demo.tap
include $(ZXEVO_SDK_PATH)/lib/tsconf/tsconf.mk

demo.tap: main.c $(TSCONF_LIB)
	$(ZCC) $(TSCONF_BASIC48_FLAGS) -m -create-app -o demo main.c
```

Для TAP под BaseConf используйте его Make-фрагмент, `$(BASECONF_LIB)` и `$(BASECONF_BASIC48_FLAGS)`.
Сначала из SDK соберите `appmake` командой
`make appmake Z88DK_SRC=/path/to/z88dk/src`. Для этой сборки также нужны
хостовый C-компилятор, `patch` и файлы разработки GMP. Профиль BASIC 48 для TSConf использует
стандартный appmake из z88dk. [BaseConf appmake](tools/appmake/README.ru.md)

Профиль BASIC 48 отключает stdio в CRT. Для форматированного вывода используйте
`zx_console_printf()` из `<zx/printf.h>` после настройки консоли целевой конфигурации.
[Общие API](lib/common/README.ru.md)

`make examples` собирает примеры BaseConf и TSConf в отдельные BASIC 48 TAP. Для одной конфигурации
используйте `make examples-baseconf` или `make examples-tsconf`. Исходники лежат в `examples/`
соответствующей библиотеки, а TAP-файлы попадают в её `build/examples/`.
[Примеры BaseConf](lib/baseconf/README.ru.md#тесты-и-примеры) ·
[Примеры TSConf](lib/tsconf/README.ru.md#запуск-из-basic-48) ·
[Загрузка TAP](lib/common/README.ru.md#профиль-запуска-из-basic-48)

## Тесты

Раннеру нужны Python 3 и ZEsarUX с ZRCP и поддержкой оборудования, к которому обращается тест.
`make test` запускает наборы BaseConf, TSConf и `common`. Отдельные наборы запускаются через
`make test-baseconf`, `make test-tsconf` и `make test-common`. Общие кейсы выполняются на обеих
конфигурациях.

```sh
make test ZESARUX=/path/to/zesarux ZXEVO_TEST_ROM=/path/to/ZXEVO.ROM
python3 lib/tsconf/tests/run.py check --case video/video
```

`ZESARUX` задаёт исполняемый файл эмулятора. По умолчанию раннер ищет его в `PATH` и стандартных
каталогах. `ZXEVO_TEST_ROM` переопределяет ROM эмулятора только для профилей `ers-rom` и `ts-bios`.
Укажите ROM, подходящий выбранной конфигурации и профилю. Некоторым кейсам нужна дополнительная
поддержка эмулятора, например последовательный мост к хосту. Для части периферии тесты проверяют
протокол драйвера на фикстурах. [Тестовая инфраструктура](lib/test_support/README.ru.md) ·
[Тесты BaseConf](lib/baseconf/tests/README.ru.md) ·
[Тесты TSConf](lib/tsconf/README.ru.md#emulator-tests) ·
[Общие тесты](lib/common/tests/README.ru.md)

Бинарники и манифесты сохраняются в `tests/build/`, отчёты и снимки в `tests/out/` соответствующей
библиотеки. Общий набор добавляет подкаталог `baseconf/` или `tsconf/`. `make clean` удаляет
результаты сборок и тестов SDK и кэш Python.

## Инструменты

- `python3 tools/profiling/memory.py path/to/program.map --sort size` показывает области памяти,
  модули и диапазоны функций по карте линковки z88dk, созданной с флагом `-m`.
- `python3 -m tools.profiling.cpu` измеряет время функции и выбранных вызовов из TAP в
  отдельном процессе ZEsarUX. По умолчанию берёт `.map` рядом с TAP. Время вложенного вызова
  учитывается в стоимости внешнего. Флаг `--output` сохраняет замеры по вызовам в JSON. Измеряемые
  функции должны находиться в резидентном коде, а аргументы со стека снимает вызывающая сторона. Для
  другой последовательности запуска используйте `--keys` без последнего Enter. Флаги `--zesarux` и
  `--rom` позволяют выбрать эмулятор и ROM.
- ZXHost предоставляет почтовый ящик в памяти целевой программы и инструменты Python для её загрузки
  и управления через ZRCP. [ZXHost](lib/test_support/README.ru.md#zxhost-target-runtime-and-mailbox)
- `make format` форматирует C, ASM и Markdown. [Форматтер](tools/formatter/README.ru.md)

Чтобы измерить отрисовку Night Train после `make examples-baseconf`, выполните из корня SDK:

```sh
python3 -m tools.profiling.cpu \
  --tap lib/baseconf/build/examples/night_train.tap --entry draw_station \
  --functions zx_draw_fill_rect zx_console_draw_op zx_console_clear
```
