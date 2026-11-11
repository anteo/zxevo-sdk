.DEFAULT_GOAL := help

.PHONY: help
help:
	@printf '%s\n' 'make format  Format Z80 test support sources'

FORMAT_FILES := $(wildcard include/*.h src/*.c)
include ../../tools/formatter/formatter.mk
