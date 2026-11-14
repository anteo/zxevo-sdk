Z88DK_SRC ?=

.PHONY: all test clean help
all:
	@test -n "$(Z88DK_SRC)" || { echo "Set Z88DK_SRC to the z88dk src directory" >&2; exit 2; }
	Z88DK_SRC="$(Z88DK_SRC)" ./build.sh

test:
	@$(MAKE) --no-print-directory -C tests test

help:
	@printf '%s\n' \
	  'make [all|test|clean|help] Z88DK_SRC=/path/to/z88dk/src' \
	  '  all    Build z88dk appmake with BaseConf/TSConf TAP and TSConf SPG support' \
	  '  test   Verify banked TAP loading in BaseConf and TSConf in ZEsarUX' \
	  '  clean  Remove build/' \
	  'See README.en.md for setup.'

clean:
	rm -rf build

FORMAT_FILES := $(wildcard *.c *.h *.md tests/*.asm)
FORMATTER_ARGS := --dialect=z80asm
include ../formatter/formatter.mk
