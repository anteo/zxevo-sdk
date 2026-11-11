.DEFAULT_GOAL := test

PYTHON ?= python3

.PHONY: test build list clean
test build list:
	$(PYTHON) run.py $(if $(filter test,$@),check,$@)

clean:
	$(PYTHON) -B run.py clean

FORMAT_FILES := $(shell find cases -type f -name '*.c')
include ../../../tools/formatter/formatter.mk
