.DEFAULT_GOAL := build
ROOT := ../../..
include ../baseconf.mk
PYTHON ?= python3
TEST_RUNNER := $(ROOT)/tools/test_runner/runner.py
INSTRUCTIONS ?= 50000000
BUILD := build
TEST_MODE ?= 4
TEST_FONT ?= 5
TEST_SCROLL ?= 0
APP := $(BUILD)/console-printf-$(TEST_MODE)-$(TEST_FONT)$(if $(filter 1,$(TEST_SCROLL)),-scroll,)
CODE_ORG ?= 0x8000
STACK_ORG ?= 0xFF00
DATA_ORG ?= 0xD800
BSS_ORG ?= 0xD900
ifneq ($(filter $(TEST_MODE),4 5 6),)
CODE_ORG := 0x8000
STACK_ORG := 0x8000
DATA_ORG := 0x5F40
BSS_ORG := 0x5F50
APPMAKE_OPTIONS := -Cz--clearaddr=0x5E00
endif
COMMON = +$(BASECONF_CFG) $(BASECONF_ABI_FLAGS) -SO3 -m \
	-L$(BASECONF_BUILD) -Ca-I$(CURDIR) \
	-pragma-define:CRT_MODEL=0 -pragma-define:MMAP=-1 \
	-pragma-define:CRT_ORG_CODE=$(CODE_ORG) -pragma-define:CRT_ORG_DATA=$(DATA_ORG) \
	-pragma-define:CRT_ORG_BSS=$(BSS_ORG) \
	-pragma-define:REGISTER_SP=$(STACK_ORG)
INCLUDES := $(BASECONF_INCLUDE_FLAGS)

.PHONY: all build run run-crt clean help
all: build
build: $(APP).tap

help:
	@printf '%s\n' \
	  'make [build|run|run-crt|test|shots|clean|help]' \
	  '  build            Build the standalone console TAP (default)' \
	  '  run, run-crt     Run the standalone console TAP or CRT probe' \
	  '  test             Build and compare library tests in ZEsarUX' \
	  '  shots            Update reference outputs from passing library tests' \
	  '  framework-list   List cases and reference outputs' \
	  '  framework-build  Build cases without running them' \
	  '  framework-clean  Remove test build and output directories' \
	  '  clean            Remove build/' \
	  '  TEST_MODE, TEST_FONT, TEST_SCROLL and INSTRUCTIONS configure the console probe.' \
	  'Run $(PYTHON) $(TEST_RUNNER) baseconf check --case core/helpers to select a case.' \
	  'See README.en.md for profiles and emulator options.'

ensure-baseconf:
	$(MAKE) -C .. ZCC="$(ZCC)" Z80ASM="$(Z80ASM)" BASECONF_CONSOLE_NO_DEFAULT_FONT=$(BASECONF_CONSOLE_NO_DEFAULT_FONT)

$(BASECONF_LIB): | ensure-baseconf

$(APP).tap: Makefile console_printf.c mmap.inc $(BASECONF_LIBRARY_INPUTS) $(BASECONF_CRT_INPUTS) $(BASECONF_LIB) $(ZX_APPMAKE_BIN)
	mkdir -p $(BUILD)
	PATH=$(dir $(ZX_APPMAKE_BIN)):$$PATH $(ZCC) $(COMMON) $(INCLUDES) -DCONSOLE_TEST_MODE=$(TEST_MODE) -DCONSOLE_TEST_FONT=$(TEST_FONT) -DCONSOLE_TEST_SCROLL=$(TEST_SCROLL) -create-app -Cz+baseconf -Cz--name=BCONSOLE $(APPMAKE_OPTIONS) -o $(APP) console_printf.c

run: build
	$(PYTHON) $(ROOT)/tools/zesarux/tap_runner.py --tap $(APP).tap --machine BaseConf --tape-at-start --keys 'i;w40;load;quote;quote;enter;w40' --instructions $(INSTRUCTIONS) --shot $(APP).png --log $(APP).log --report $(APP)-report.txt

$(BUILD)/console-crt.tap: Makefile console_crt.c mmap.inc $(BASECONF_LIBRARY_INPUTS) $(BASECONF_CRT_INPUTS) $(BASECONF_LIB) $(ZX_APPMAKE_BIN)
	mkdir -p $(BUILD)
	PATH=$(dir $(ZX_APPMAKE_BIN)):$$PATH $(ZCC) $(COMMON) $(INCLUDES) -pragma-define:CRT_ENABLE_STDIO=1 \
		-create-app -Cz+baseconf -Cz--name=BCCRT -o $(BUILD)/console-crt console_crt.c

run-crt: $(BUILD)/console-crt.tap
	$(PYTHON) $(ROOT)/tools/zesarux/tap_runner.py --tap $(BUILD)/console-crt.tap --machine BaseConf --tape-at-start --keys 'i;w40;load;quote;quote;enter;w40' --instructions $(INSTRUCTIONS) --shot $(BUILD)/console-crt.png --log $(BUILD)/console-crt.log --report $(BUILD)/console-crt-report.txt

clean: framework-clean
ifneq ($(abspath $(BUILD)),$(CURDIR)/build)
	rm -rf -- "$(BUILD)"
endif

.NOTPARALLEL:

# BaseConf test framework: one .c per case, recursively discovered under
# tests/cases. The TAP targets above remain for the old ad-hoc probes.
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

FORMAT_FILES := $(wildcard *.c *.h *.asm *.inc *.md) \
	$(shell find cases support -type f \( -name '*.c' -o -name '*.h' -o -name '*.asm' -o -name '*.inc' -o -name '*.md' \))
FORMATTER_ARGS := --dialect=z80asm
include ../../../tools/formatter/formatter.mk
