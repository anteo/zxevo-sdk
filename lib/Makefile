.DEFAULT_GOAL := help

.PHONY: help clean
help:
	@printf '%s\n' 'make format  Format library sources' 'make clean   Remove library and test outputs'

clean:
	$(MAKE) -C baseconf clean
	$(MAKE) -C tsconf clean
	$(MAKE) -C common/tests clean

FORMAT_SUBDIRS := baseconf test_support tsconf
FORMAT_FILES := $(wildcard common/crt/*.asm common/src/*/z80/*.asm common/src/*/z80/*.inc common/include/zx/*.h common/*.c common/*.md)
FORMAT_FILES += $(wildcard common/src/*/c/*.c common/src/*/*.h)
FORMAT_FILES += $(wildcard common/tests/cases/*/*.c common/tests/cases/*/*.asm common/tests/*.md)
FORMATTER_ARGS := --dialect=z80asm
include ../tools/formatter/formatter.mk
