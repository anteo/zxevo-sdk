Z88DK_SRC ?=

.PHONY: all clean help
all:
	@test -n "$(Z88DK_SRC)" || { echo "Set Z88DK_SRC to the z88dk src directory" >&2; exit 2; }
	Z88DK_SRC="$(Z88DK_SRC)" ./build.sh

help:
	@printf '%s\n' \
	  'make [all|clean|help] Z88DK_SRC=/path/to/z88dk/src' \
	  '  all    Build the z88dk appmake with the BaseConf format (default)' \
	  '  clean  Remove build/' \
	  'See README.en.md for setup.'

clean:
	rm -rf build

FORMAT_FILES := $(wildcard *.c *.h *.md)
include ../formatter/formatter.mk
