.DEFAULT_GOAL := test

PYTHON ?= python3
TEST_RUNNER := ../../../tools/test_runner/runner.py

.PHONY: test build list clean
test build list:
	@$(PYTHON) $(TEST_RUNNER) tsconf $(if $(filter test,$@),check,$@)

clean:
	$(PYTHON) -B $(TEST_RUNNER) tsconf clean

FORMAT_FILES := $(shell find cases -type f -name '*.c')
include ../../../tools/formatter/formatter.mk
