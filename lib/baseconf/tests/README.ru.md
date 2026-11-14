# Тесты BaseConf

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

Здесь находятся кейсы BaseConf, адаптер машины и отдельные TAP для проверки консоли. Общий раннер
собирает кейсы, загружает их в ZEsarUX через ZRCP и сравнивает результаты, полученные через ZXHost.
[Инфраструктура](../../../tools/test_runner/README.ru.md) ·
[Общие кейсы](../../common/tests/README.ru.md) · [Замеры вывода шрифтов](../bench/README.ru.md)

## Запуск

Команды выполняются из корня SDK. Нужны `zcc`, `z88dk-z80asm`, Python 3.11 или новее и ZEsarUX с
ZRCP. `ZESARUX` указывает исполняемый файл, `ZXEVO_TEST_ROM` переопределяет ROM для профиля
`ers-rom`.

```sh
make -C lib/baseconf/tests test
make -C lib/baseconf/tests framework-list
make -C lib/baseconf/tests shots
python3 tools/test_runner/runner.py baseconf check --case core/helpers
python3 tools/test_runner/runner.py baseconf check --case core
```

Раннер рекурсивно находит C-файлы в `cases/`, читает необязательный TOML с тем же именем и выбирает
профиль из `profiles.toml`. Файлы, начинающиеся с `_`, не считаются отдельными кейсами. Эталоны
лежат рядом с исходником. Адаптер в `tools/test_runner/suites/baseconf.py` задаёт компилятору
профиль и начальное отображение страниц. `support/` содержит `bc_case.h`, `bc_case.c` и раскладку
`mmap.inc`.

## Сборка и карта памяти

Раннер собирает целевую библиотеку и кейс через zcc с `+config/baseconf.cfg`, classic SDCC,
`-SO3 -m`, подключает `support/bc_case.c`, `zx_test.c` и `zx_host.c`. Заголовок `zx_host_config.h`
генерируется из `lib/test_support/protocol.json`. По карте линковки раннер сверяет адреса и границы.
Затем создаёт `manifest.json` и бинарные блоки в `build/<группа>/<кейс>/<профиль>/`.

Профиль по умолчанию использует следующую раскладку.

| Окно | Адреса        | Назначение                                                  |
| ---- | ------------- | ----------------------------------------------------------- |
| W0   | `0000h–3FFFh` | RAM-страница 32, векторы и начало кода                      |
| W1   | `4000h–7FFFh` | RAM-страница 33, продолжение кода, ZXHost, DATA, BSS и стек |
| W2   | `8000h–BFFFh` | Может использоваться под экранную страницу                  |
| W3   | `C000h–FFFFh` | Может использоваться под вторую экранную страницу           |

| Область          | Адреса и ограничения                                |
| ---------------- | --------------------------------------------------- |
| Код и rodata     | `0100h–5FFFh`, не более 24 320 байт                 |
| Заголовок ZXHost | `6000h–601Fh`, 32 байта                             |
| Лог ZXHost       | `6100h–67FFh`, 1792 байта                           |
| DATA             | `6800h–6FFFh`, 2 КиБ                                |
| BSS              | С `7000h`. До вершины стека остаётся не менее 1 КиБ |
| Стек             | С `7E00h` вниз                                      |

Для кода в W0 раннер устанавливает `RET` в RST-векторах `0008h–0030h`, `RETI` в `0038h` и `RETN` в
`0066h`. Тесты начинают с отключёнными маскируемыми IRQ. Профиль `ers-rom` оставляет ROM в W0 и
запускает код из W2. Большие неизменяемые таблицы помечайте `const`, чтобы они попали в rodata.

## Как написать кейс

CRT вызывает `zx_init()` до входа в кейс. `bc_case_init()` инициализирует ZXHost, устанавливает
`BC_ERS_NONE`, закрепляет окна из профиля и задаёт бордюр 0, ink 7 и paper 0. Завершайте кейс
вызовом `zx_test_finish()`.

```c
#include <baseconf.h>
#include "bc_case.h"

int main(void) {
    if (bc_case_init() == ZX_OK) {
        ZX_ASSERT(bc_select_screen(ZX_SCREEN_0) == ZX_OK);
        if (bc_set_video_mode(BC_VIDEO_ATM_640) == ZX_OK) {
            zx_set_ink(7);
            ZX_ASSERT(zx_console_clear() == ZX_OK);
            zx_draw_line(0, 0, 639, 199);
            zx_test_step_shot("atm640");
        } else {
            zx_test_step_skip("atm640", "mode unavailable");
        }
    }
    zx_test_finish();
    return 0;
}
```

| Функция                                              | Результат шага                                                  |
| ---------------------------------------------------- | --------------------------------------------------------------- |
| `ZX_ASSERT(condition)` и `zx_test_step_marker(name)` | Проверка без файла. Неудачное утверждение отмечает шаг как FAIL |
| `zx_test_step_shot(name)`                            | Снимок `.png`                                                   |
| `zx_test_output_*()` и `zx_test_step_text(name)`     | Текст `.txt`. Буфер рассчитан на 512 байт                       |
| `zx_test_step_data(name, ptr, len)`                  | Шестнадцатеричный дамп `.txt`                                   |
| `zx_test_step_binary(name, ptr, len)`                | Бинарный файл `.bin`                                            |
| `zx_test_step_skip(name, reason)`                    | Пропуск с причиной                                              |

На каждом шаге программа останавливается в ожидании следующего запроса. При передаче данных запись
`DATA <addr> <len> <kind>` указывает адрес, длину `uint16_t` и формат. `kind` равен 0 для дампа, 1
для текста и 2 для бинарных данных. Оставляйте буфер доступным CPU, пока хост читает его. Снимок
обычно делается через 200 000 циклов после сообщения `DONE`.

### Протокол шагов

`result0` задаёт статус (`0` PASS, `1` FAIL, `2` SKIP), `result1` содержит индекс шага с нуля,
`result2` содержит флаги (`1` снимок, `2` следующий шаг, `4` данные), `result3` равен 0. Лог
содержит имя шага и, при необходимости, запись `DATA` или `FAIL line=<n> <expression>`.

Перед запуском хост отправляет запрос `sequence=1`. Кейс публикует `DONE` и ждёт. Хост читает ответ
с тем же номером, затем при наличии следующего шага записывает новый запрос, записав `sequence`
последним. Кейс вызывает `zx_host_init()` и продолжает.
[ZXHost](../../../tools/test_runner/README.ru.md)

## Метаданные и профили

Необязательный `cases/<группа>/<кейс>.toml` может задавать описание, профили запуска, тайм-аут шага,
дополнительные `-D` и исходники относительно C-файла.

```toml
description = "classic printf/gotoxy"
profile = "stdio+no-font8"
timeout = 45
defines = ["SOME_PARAMETER=1"]
sources = ["extra.c"]
```

Для нескольких запусков укажите `profiles = ["stdio+no-font8", "stdio"]`. Для каждого запуска раннер
сначала применяет родителей из `parent`, затем объединяет слои из имени по порядку. Профили BaseConf
наследуют `[profiles.default]`. Без обоих полей кейс запускается с `default`. Конфликтующие
присваивания параметров сборки вызывают ошибку. По умолчанию CRT выключает stdio. Для сценариев со
стандартными потоками или `printf()` добавьте слой `stdio`.

| Слой              | Настройка                                                                 |
| ----------------- | ------------------------------------------------------------------------- |
| `stdio`           | `CRT_ENABLE_STDIO=1` включает CRT stdio и его обработчик вывода           |
| `no-stdio`        | `CRT_ENABLE_STDIO=0` отключает CRT stdio и его обработчик вывода          |
| `no-font8`        | `BASECONF_CONSOLE_NO_DEFAULT_FONT=1` отключает автоматический выбор font8 |
| `no-primitives`   | `BASECONF_VIDEO_PRIMITIVE_MODES=NONE` исключает графические примитивы     |
| `multicolor-text` | Собирает текст для Multicolor и примитивы для ZX                          |
| `memory-maps`     | Дублирует резидентные страницы в обе карты                                |
| `ers-rom`         | Оставляет ROM в W0 и переносит кейс в W2                                  |
| `zx-screen-w1`    | Оставляет страницу ZX-экрана 5 в W1 для оконных функций ERS               |

Профиль задаёт `layout`, `cflags`, `defines` и настройки `library`. Поля `library.build_dir`,
`library.make_targets`, `library.make_args` и `library.extra_libs` выбирают каталог, цели и
параметры сборки библиотеки и дополнительные `-l`. Повторяемый `--profile` выбирает запуски по
полному имени профиля, например `no-stdio+no-font8`.

`emulator_args` передаёт дополнительные аргументы ZEsarUX. В `emulator_steps` ключом служит имя
шага. После возобновления раннер может вызвать `nmi`, выполнить `settle` циклов, передать
`before_shot_keys`, снять `shot` и передать `keys`. Сценарий клавиш может выглядеть как `f;break;0`.
`region: [x, y, width, height]` ограничивает сравнение снимка областью, при этом файл содержит весь
экран. `uart.send` и `uart.expect` передают и принимают байты через псевдотерминал POSIX, пока кейс
ждёт продолжения. Для этого нужна сборка ZEsarUX с `--uartbridge-file` и мостом UART.

## Эталоны и отчёты

Общие файлы `<кейс>.<NN>_<тег>.<ext>` лежат в `cases/<группа>/<кейс>/`. Отличающиеся и
дополнительные файлы лежат в подкаталоге `<профиль>/`. `NN` начинается с 1, тег берётся из имени
шага. Раннер приводит его к нижнему регистру, заменяет группы символов вне ASCII-букв и цифр
дефисами и ограничивает длину 40 символами. Пустое имя даёт `out`.

Результаты с такими же именами, отчёт `<кейс>.report.json` и лог `<кейс>.zesarux.log` попадают в
`build/<группа>/<кейс>/<профиль>/` рядом с бинарниками и манифестом. При несовпадении раннер
указывает отличия пикселей и сохраняет `.diff.png`, выводит текстовый diff или показывает первое
отличающееся смещение в бинарных данных. Отсутствующий или лишний эталон считается ошибкой.

`make -C lib/baseconf/tests shots` или `runner.py baseconf check --update` обновляет эталоны после
успешного запуска. Первый профиль обновляет общие файлы и свои переопределения, остальные сохраняют
отличия. `runner.py baseconf clean` удаляет `build/` и локальный кэш Python. С `--case` очистка
касается только выбранных кейсов.

```sh
python3 tools/test_runner/runner.py baseconf list [--case PATH]
python3 tools/test_runner/runner.py baseconf build [--case PATH] [--profile NAME]
python3 tools/test_runner/runner.py baseconf check [--case PATH] [--filter REGEX]
                                       [--update] [--no-build] [--fail-fast]
                                       [--timeout SEC] [--port N] [--zesarux PATH] [--verbose]
python3 tools/test_runner/runner.py baseconf clean [--case PATH]
```

`check` используется по умолчанию. `--case` принимает путь относительно `cases/`, имя каталога или
уникальное имя файла без `.c`. Опцию можно повторять. `--no-build` использует последний манифест
выбранного профиля. Тайм-аут шага по умолчанию составляет 30 секунд. `--fail-fast` останавливается
после первого кейса с несовпавшим результатом. Коды выхода — `0` для успеха, `1` для неудачного
кейса или ошибки сборки и `2` для ошибки эмулятора или раннера.

## Покрытие и ограничения

Актуальный список показывает `make -C lib/baseconf/tests framework-list`. Группы `core` и `memory`
проверяют инициализацию, страницы, временные отображения, Flash и кучу. `video`, `palette` и
`graphics` проверяют режимы, палитры, рисование, отсечение и прокрутку. `console` и `font` покрывают
`zx_console_printf`, CRT stdio, шрифты и вывод текста. `input`, `rtc`, `timing` и `interrupt`
проверяют PS/2, RTC, скорость CPU, IRQ и NMI. `storage` и `ers` покрывают SD, FDD и сервисы ROM.
Звук, мышь Kempston, UART, Nemo IDE, ZX-атрибуты, данные SD, версия AVR, пул страниц и куча также
проверяются общим набором. [Общие тесты](../../common/tests/README.ru.md)

Раннер стартует ZEsarUX в машине BaseConf с `--realvideo` и `--vo null`, даёт по умолчанию 500 000
итераций на запуск ROM и выполняет кейс. Профиль `ers-rom` останавливается на адресе ROM `6155h` с
пределом 2 000 000 итераций. Параллельные запуски должны использовать разные порты ZRCP. Некоторые
источники `newirq`, запись Flash и страничная EEPROM AVR зависят от поддержки оборудования в
выбранной сборке эмулятора.

## TAP для консоли

`make -C lib/baseconf/tests run TEST_MODE=0 TEST_FONT=5 TEST_SCROLL=1` собирает и запускает
отдельный TAP с `zx_console_printf` в ZX256. `make -C lib/baseconf/tests run-crt TEST_MODE=0`
проверяет обычный `printf` через CRT. Отчёты и снимки этих запусков сохраняются в `tests/build/`.
