.DEFAULT_GOAL := format-plan

.PHONY: clean
clean:
	find . -type d -name __pycache__ -prune -exec rm -rf -- {} +

FORMAT_FILES := $(wildcard include/*.h src/*.c *.md)
include ../../tools/formatter/formatter.mk
