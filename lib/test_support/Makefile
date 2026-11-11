.DEFAULT_GOAL := help

.PHONY: help clean
help:
	@printf '%s\n' 'make format  Format test support sources' 'make clean   Remove Python caches'

clean:
	find . -type d -name __pycache__ -prune -exec rm -rf -- {} +

FORMAT_FILES := $(wildcard include/*.h src/*.c *.md)
include ../../tools/formatter/formatter.mk
