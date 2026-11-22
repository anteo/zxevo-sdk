.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
include ../../tsconf.mk

PYTHON ?= python3
BUILD := $(CURDIR)/build
ASSETS_TOOLS := $(wildcard $(TSCONF_ROOT)/../../tools/assets/*.py) \
    $(TSCONF_ROOT)/../../tools/assets/requirements.txt \
    $(TSCONF_ROOT)/../../tools/python/environment.py
FLAGS := $(TSCONF_APP_FLAGS) -lzx_clib \
    -pragma-define:CRT_ORG_CODE=0x4000 -pragma-define:CRT_ENABLE_STDIO=0 \
    -pragma-define:CRT_INITIALIZE_BSS=1 -pragma-define:CRT_ENABLE_EIDI=0 \
    -pragma-define:__crt_org_bss=-1 \
    -pragma-define:CRT_STACK_SIZE=0 -m -create-app -Cz+tsconf -Cz--format=spg \
    -Cz--spg-stack=0xbdb0 -Cz--spg-resident=0xbc80 -Cz--spg-clock=2 -Cz--name=XNX \
    -Cz--spg-compression=auto

.PHONY: all library clean FORCE
all: $(BUILD)/xnx.spg

library:
	$(MAKE) -C $(TSCONF_ROOT) all

$(BUILD)/assets.h: assets.py $(wildcard assets/gfx/* assets/mus/* assets/sfx/*) $(ASSETS_TOOLS)
	$(PYTHON) assets.py $(BUILD)

$(BUILD)/compile-flags: FORCE
	@mkdir -p $(BUILD)
	@printf '%s\n' '$(FLAGS)' > $@.tmp
	@cmp -s $@.tmp $@ || mv $@.tmp $@
	@rm -f $@.tmp

$(BUILD)/%.o: %.c game.h resources.h Makefile ../../tsconf.mk $(TSCONF_CFG) $(TSCONF_PUBLIC_HEADERS) $(BUILD)/assets.h $(BUILD)/compile-flags
	$(ZCC) $(filter-out -L%,$(TSCONF_APP_FLAGS)) -I$(CURDIR) -I$(BUILD) -c -o $@ $<

$(BUILD)/xnx.spg: $(BUILD)/main.o $(BUILD)/platform.o $(BUILD)/assets.h $(TSCONF_LIB) $(ZX_APPMAKE_BIN) | library
	cd $(BUILD) && $(ZCC) $(FLAGS) -o xnx main.o platform.o assets.asm

clean:
	rm -rf -- $(BUILD)

$(TSCONF_LIB): | library

FORMAT_FILES := $(wildcard *.c *.h *.md)
FORMATTER_ARGS := --dialect=z80asm
include ../../../../tools/formatter/formatter.mk
