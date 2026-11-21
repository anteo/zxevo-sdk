.DEFAULT_GOAL := test

TEST_RUNNER_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
PYTHON ?= python3
CASE ?=
export ZX_TEST_CASE := $(strip $(CASE))
export ZX_TEST_JOBS := $(strip $(JOBS))
CASE_ARG = $(if $(ZX_TEST_CASE),--case "$$ZX_TEST_CASE")

.NOTPARALLEL:

.PHONY: all test build list shots clean help
all: test

test build list shots:
	@$(PYTHON) "$(TEST_RUNNER_DIR)/runner.py" $(TEST_SUITE) \
		$(if $(filter test shots,$@),check,$@) $(if $(filter shots,$@),--update) $(CASE_ARG) \
		$(if $(and $(filter test,$@),$(ZX_TEST_JOBS)),--jobs "$$ZX_TEST_JOBS") \
		$(if $(and $(filter test,$@),$(filter 1,$(FAIL_FAST))),--fail-fast) \
		$(if $(and $(filter test,$@),$(filter 1,$(RERUN_FAILED))),--rerun-failed) \
		$(if $(and $(filter test,$@),$(filter 1,$(CONTINUE))),--continue)

clean:
	@$(PYTHON) -B "$(TEST_RUNNER_DIR)/runner.py" $(TEST_SUITE) clean

help:
	@printf '%s\n' \
	  'make [test|build|list|shots|clean|format|help]' \
	  '  test    Build and run tests in ZEsarUX (default)' \
	  '  build   Build cases without running them' \
	  '  list    List cases and reference outputs' \
	  '  shots   Update reference outputs from passing tests' \
	  '  clean   Remove test build outputs and Python caches' \
	  '  format  Format test sources and documentation' \
	  'Pass CASE=<group or case> to test, build, list or shots.' \
	  'Pass JOBS=N to run up to N emulators concurrently (default 1).' \
	  'Pass FAIL_FAST=1, RERUN_FAILED=1 or CONTINUE=1 to test.'

FORMAT_FILES := $(wildcard *.md) \
	$(shell find cases $(wildcard support) -type f \( -name '*.c' -o -name '*.h' -o -name '*.asm' -o -name '*.inc' -o -name '*.md' \))
FORMATTER_ARGS := --dialect=z80asm
include $(TEST_RUNNER_DIR)/../formatter/formatter.mk
