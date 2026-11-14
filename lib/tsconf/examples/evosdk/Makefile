.DEFAULT_GOAL := all
.DELETE_ON_ERROR:

include ../../tsconf.mk

PYTHON ?= python3
COMPRESSION ?= zx0
ZX0 ?= z88dk-zx0
BUILD := $(CURDIR)/build/$(COMPRESSION)
ASSETS_TOOLS := $(wildcard $(TSCONF_ROOT)/../../tools/assets/*.py) \
    $(TSCONF_ROOT)/../../tools/assets/requirements.txt \
    $(TSCONF_ROOT)/../../tools/python/environment.py
PROGRAMS := empty font_keyboard mouse_joystick sprites slideshow
TAPS := $(addprefix $(BUILD)/,$(addsuffix /demo.tap,$(PROGRAMS)))
# Explicitly use the Spectrum implementations of games.h/input.h. TSConf's
# default target only links the generic Z80 libc.
# Classic CRT uses __crt_org_bss directly. A separate BSS section prevents
# the 2 KiB decode buffer from being serialized into the main TAP block.
APP_FLAGS = $(TSCONF_APP_FLAGS) -lzx_clib \
    -crt0=$(ZX_COMMON_ROOT)/crt/basic48_crt0.asm -pragma-define:__crt_org_bss=0xb000 \
    -m -create-app -Cz+tsconf

.PHONY: all library clean FORCE
all: $(TAPS)

library:
	$(MAKE) -C $(TSCONF_ROOT) all

$(BUILD)/compile-flags: FORCE
	@mkdir -p $(BUILD)
	@printf '%s\n' '$(APP_FLAGS)' '$(COMPRESSION)' '$(ZX0)' > $@.tmp
	@cmp -s $@.tmp $@ || mv $@.tmp $@
	@rm -f $@.tmp

$(BUILD)/%/resources.h: assets.py $(ASSETS_TOOLS) $(wildcard assets/*/*.bmp) $(BUILD)/compile-flags
	$(PYTHON) assets.py $* $(BUILD)/$* --compression $(COMPRESSION) --compressor $(ZX0)

$(BUILD)/%/demo.tap: %.c demo.h $(BUILD)/%/resources.h Makefile $(TSCONF_LIB) $(ZX_APPMAKE_BIN) $(BUILD)/compile-flags | library
	cd $(BUILD)/$* && $(ZCC) $(APP_FLAGS) -I$(CURDIR) -I. \
	    -Cz--name=EVODEMO -o demo $(CURDIR)/$*.c resources.asm

$(TSCONF_LIB): | library

clean:
	rm -rf -- $(CURDIR)/build

.SECONDARY:

FORMAT_FILES := $(wildcard *.c *.h *.md)
FORMAT_SUBDIRS := xnx
FORMATTER_ARGS := --dialect=z80asm
include ../../../../tools/formatter/formatter.mk
