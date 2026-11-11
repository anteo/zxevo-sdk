.DEFAULT_GOAL := format-plan

.PHONY: clean
clean:
	$(MAKE) -C baseconf clean
	$(MAKE) -C tsconf clean
	$(MAKE) -C common/tests clean
	$(MAKE) -C test_support clean

FORMAT_SUBDIRS := baseconf test_support tsconf
FORMAT_FILES := $(wildcard common/*.asm common/src/*/z80/*.asm common/src/*/z80/*.inc common/include/zx/*.h common/*.c common/*.md)
FORMAT_FILES += $(wildcard common/src/*/c/*.c common/src/*/*.h)
FORMAT_FILES += $(wildcard common/tests/cases/*/*.c common/tests/cases/*/*.asm common/tests/*.md)
FORMATTER_ARGS := --dialect=z80asm
include ../tools/formatter/formatter.mk
