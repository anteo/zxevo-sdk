# Форматтеры исходников

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

| Программа    | Назначение                         | Основные опции                         |
| ------------ | ---------------------------------- | -------------------------------------- |
| `formatter`  | Выбирает форматтер по расширению   | `--EXT-formatter=PROGRAM`, `-h`        |
| `format_asm` | ASM через `awk`                    | `--dialect`, `--check`                 |
| `format_c`   | C и заголовки через `clang-format` | `--clang-format`, `--style`, `--check` |
| `format_md`  | Markdown через Prettier            | `--prettier`, `--config`, `--check`    |

```sh
tools/formatter/formatter --dialect=z80asm lib/common/src/color/z80 lib/common/include/zx README.md
tools/formatter/formatter --check lib/common/include/zx
tools/formatter/format_asm --dialect z80asm lib/common/src/color/z80
tools/formatter/format_c --clang-format /opt/bin/clang-format examples
tools/formatter/format_md README.md README.ru.md
```

## Диспетчер

По умолчанию `*.c` и `*.h` передаются в `format_c`, `*.md` в `format_md`, остальные расширения в
`format_asm`. Диспетчер сначала ищет обработчик рядом с собой, затем в `PATH`.
`--EXT-formatter=PROGRAM` переопределяет обработчик для расширения, например
`--inc-formatter=format_asm`.

Передаваемые опции с аргументами записывайте одним словом, например `--dialect=z80asm`. Обработчики
объявляют поддерживаемые опции через `--options`. Диспетчер передаёт им подходящие аргументы и
отделяет файлы через `--`. Код выхода соответствует наибольшему статусу вызванных обработчиков. `0`
означает успех, `1` при `--check` означает необходимость форматирования, `2` означает ошибку запуска
или аргументов.

## Обработчики

Каждому обработчику можно передать список файлов или каталоги. При обработке каталога `format_asm`
выбирает `*.asm`, `format_c` выбирает `*.c` и `*.h`, `format_md` выбирает `*.md`. Явно переданный
файл обрабатывается независимо от расширения. Файл перезаписывается после успешного форматирования,
если его содержимое изменилось.

- `format_asm --dialect NAME` выбирает `sjasm` или `z80asm`. При прямом вызове значение по умолчанию
  берётся из `FORMAT_ASM_DIALECT`, затем используется `sjasm`.
- `format_c --clang-format PATH` выбирает исполняемый файл. По умолчанию используется `CLANG_FORMAT`
  или `clang-format`. `--style PATH` заменяет встроенный `z88dk-c.clang-format`.
- `format_md --prettier PATH` выбирает исполняемый файл. По умолчанию используется `PRETTIER` или
  `prettier`. `--config PATH` заменяет `tools/formatter/.prettierrc.json`. Встроенная конфигурация
  переносит обычный текст на ширине 100 столбцов. Prettier выравнивает столбцы таблицы и сохраняет
  каждую строку таблицы одной строкой исходника, даже если таблица шире 100 столбцов.

Правила `sjasm` выравнивают инструкции, метки и константы, используют восьмипробельный отступ для
инструкций и директив и заменяют `#hex` на `0xhex`. Правила `z80asm` меняют отступы и пустые строки.
Операнды, литералы `00BFh`, локальные метки, `AF'` и пробелы перед комментариями сохраняются. Стиль
`z88dk-c` задаёт отступ 4, предел 100 столбцов, открывающие скобки на той же строке и правое
выравнивание указателей. Он сохраняет порядок `#include` и объявляет `__z88dk_fastcall` макросом
атрибута. Редакторы могут использовать
`clang-format --style=file:tools/formatter/z88dk-c.clang-format`.

## Подключение в Makefile

```makefile
FORMAT_FILES   := $(wildcard src/*.c src/*.h src/*.asm)
FORMATTER_ARGS := --dialect=z80asm

include ../tools/formatter/formatter.mk
```

Подключайте фрагмент после собственных целей проекта. `FORMAT_SUBDIRS` перечисляет каталоги, в
которые Make передаёт вызов. Каждый каталог выбирает свои файлы и диалект. Локальный список
`FORMAT_FILES` может быть пустым. `FORMATTER_ARGS` передаётся диспетчеру. Для своего бинарника можно
задать `make CLANG_FORMAT=/path format` или передать `--clang-format=$(CLANG_FORMAT)`.

`make format` передаёт `$(FORMAT_FILES)` диспетчеру и вызывает `format` в каталогах `FORMAT_SUBDIRS`.

Чтобы обработать один язык, вызовите обработчик напрямую, например
`tools/formatter/format_c src include`.

## Добавление обработчика

Программа должна принимать список файлов и опцию `--check`. Через `--options` она может вывести по
одному имени поддерживаемой опции на строку без дефисов. Обработчику без поддержки `--options`
диспетчер передаст все опции. Свяжите расширение с программой через `--EXT-formatter=PROGRAM`.
