.DEFAULT_GOAL := help

.PHONY: help
help:
	@printf '%s\n' 'make format  Format Z80 test support sources'

FORMAT_FILES := $(wildcard c/*.h c/*.c z80/*.asm z80/*.inc)
include ../../tools/formatter/formatter.mk
