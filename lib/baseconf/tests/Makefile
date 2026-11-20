.DEFAULT_GOAL := test

PYTHON ?= python3
TEST_RUNNER := ../../../tools/test_runner/runner.py

.PHONY: all clean help
all: test
clean: framework-clean

help:
	@printf '%s\n' \
	  'make [test|shots|framework-list|framework-build|clean|help]' \
	  '  test             Build and compare library tests in ZEsarUX (default)' \
	  '  shots            Update reference outputs from passing tests' \
	  '  framework-list   List cases and reference outputs' \
	  '  framework-build  Build cases without running them' \
	  '  clean            Remove test build outputs and Python caches' \
	  'See README.en.md for profiles and emulator options.'

.NOTPARALLEL:

.PHONY: test shots framework-list framework-build framework-check framework-update framework-clean
test: framework-check
shots: framework-update

framework-list:
	$(PYTHON) $(TEST_RUNNER) baseconf list

framework-build:
	@$(PYTHON) $(TEST_RUNNER) baseconf build

framework-check:
	@$(PYTHON) $(TEST_RUNNER) baseconf check

framework-update:
	$(PYTHON) $(TEST_RUNNER) baseconf check --update

framework-clean:
	$(PYTHON) -B $(TEST_RUNNER) baseconf clean

FORMAT_FILES := $(wildcard *.md) \
	$(shell find cases support -type f \( -name '*.c' -o -name '*.h' -o -name '*.asm' -o -name '*.inc' -o -name '*.md' \))
FORMATTER_ARGS := --dialect=z80asm
include ../../../tools/formatter/formatter.mk
