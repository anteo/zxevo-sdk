.DEFAULT_GOAL := test

SDK_ROOT := $(abspath ../../..)
include $(SDK_ROOT)/lib/baseconf/baseconf.mk
include $(SDK_ROOT)/lib/tsconf/tsconf.mk

PYTHON ?= python3
TEST_BUILD := $(abspath ../build/tests)
CASE_BUILD = $(TEST_BUILD)/$(@:test-%=%)

.PHONY: test test-tool test-baseconf test-tsconf
test: test-baseconf test-tsconf

define report_build_failure
cd "$(SDK_ROOT)" && $(PYTHON) -B -c \
	'import sys; from tools.test_runner.runner import console_label; print(console_label("FAIL"), sys.argv[1], sep="  ")' \
	"$(1) (see $(2))"
endef

test-tool:
	@mkdir -p "$(TEST_BUILD)"
	@$(MAKE) --no-print-directory appmake >"$(TEST_BUILD)/appmake.log" 2>&1 || { \
		$(call report_build_failure,appmake build,$(TEST_BUILD)/appmake.log); \
		exit 1; \
	}

test-baseconf: TEST_MACHINE := BaseConf
test-baseconf: TEST_CONFIG := BASECONF
test-tsconf: TEST_MACHINE := TSConf
test-tsconf: TEST_CONFIG := TSCONF

test-baseconf test-tsconf: test-tool
	@mkdir -p "$(CASE_BUILD)"
	@{ $(MAKE) --no-print-directory -C "$($(TEST_CONFIG)_ROOT)" \
			BUILD="$($(TEST_CONFIG)_BUILD)" all && \
		cd "$(CASE_BUILD)" && $(ZCC) $($(TEST_CONFIG)_APP_FLAGS) \
			-crt0="$(ZX_COMMON_ROOT)/crt/basic48_crt0.asm" -m -create-app -Cz+$(@:test-%=%) \
			-o banked "$(CURDIR)/banked.asm"; \
	} >"$(CASE_BUILD)/build.log" 2>&1 || { \
		$(call report_build_failure,$(TEST_MACHINE) banked TAP build,$(CASE_BUILD)/build.log); \
		exit 1; \
	}
	@cd "$(SDK_ROOT)" && $(PYTHON) -B -m tools.appmake.tests.banked "$(TEST_MACHINE)" "$(CASE_BUILD)/banked.tap"
