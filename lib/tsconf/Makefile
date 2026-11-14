.DEFAULT_GOAL := all
.DELETE_ON_ERROR:

include tsconf.mk

BUILD ?= $(TSCONF_BUILD)
TSCONF_VIDEO_MODES ?= ALL
TSCONF_VIDEO_60HZ ?= 0
VIDEO_MODES := ZX 16C 256C TEXT
VIDEO_MODE_SET := $(if $(filter ALL,$(TSCONF_VIDEO_MODES)),$(VIDEO_MODES),$(sort $(TSCONF_VIDEO_MODES)))
ifneq ($(filter-out $(VIDEO_MODES) ALL,$(TSCONF_VIDEO_MODES)),)
$(error Unknown TSConf video mode(s) in $(TSCONF_VIDEO_MODES))
endif
ifeq ($(VIDEO_MODE_SET),)
$(error TSCONF_VIDEO_MODES must select at least one mode)
endif
ifneq ($(TSCONF_VIDEO_60HZ),0)
ifneq ($(TSCONF_VIDEO_60HZ),1)
$(error TSCONF_VIDEO_60HZ must be 0 or 1)
endif
endif
VIDEO_DEFINES := $(addprefix TSCONF_VIDEO_,$(VIDEO_MODE_SET)) \
	$(if $(filter 16C 256C,$(VIDEO_MODE_SET)),TSCONF_VIDEO_PACKED) \
	$(if $(filter ZX 16C 256C,$(VIDEO_MODE_SET)),TSCONF_VIDEO_BITMAP) \
	$(if $(filter ZX 16C,$(VIDEO_MODE_SET)),TSCONF_VIDEO_MASKED) \
	$(if $(filter 16C 256C TEXT,$(VIDEO_MODE_SET)),TSCONF_VIDEO_RASTER) \
	$(if $(filter 4,$(words $(VIDEO_MODE_SET))),TSCONF_VIDEO_ALL) \
	$(if $(filter 1,$(TSCONF_VIDEO_60HZ)),TSCONF_VIDEO_60HZ)
VIDEO_ASMFLAGS := $(addprefix -D,$(VIDEO_DEFINES)) \
	-DTSCONF_FRAME_LINES=$(if $(filter 1,$(TSCONF_VIDEO_60HZ)),262,320)

ASM_SOURCES := $(sort $(wildcard src/*/z80/*.asm))
C_SOURCES := $(sort $(wildcard src/*/c/*.c))
SOURCES := $(ASM_SOURCES) $(C_SOURCES)
OBJECTS := $(patsubst src/%.asm,$(BUILD)/%.o,$(ASM_SOURCES)) \
	$(patsubst src/%.c,$(BUILD)/%.o,$(C_SOURCES))
COMMON_ASM := $(sort $(wildcard ../common/src/*/z80/*.asm))
COMMON_C := $(sort $(wildcard ../common/src/*/c/*.c))
COMMON_OBJECTS := $(patsubst ../common/src/%.asm,$(BUILD)/common/%.o,$(COMMON_ASM)) \
	$(patsubst ../common/src/%.c,$(BUILD)/common/%.o,$(COMMON_C))
COMMON_ASM_INCLUDE := $(ZX_COMMON_ROOT)/src
COMMON_ASM_HEADERS := $(wildcard $(COMMON_ASM_INCLUDE)/*/z80/*.inc)
COMMON_C_HEADERS := $(wildcard $(ZX_COMMON_ROOT)/include/zx/*.h $(ZX_COMMON_ROOT)/src/*/*.h)
COMMON_CFLAGS := +z80 $(TSCONF_ABI_FLAGS) -I$(ZX_COMMON_ROOT)/include
CFLAGS := $(COMMON_CFLAGS) -D__TSCONF -I$(TSCONF_INCLUDE)
HEADERS := $(wildcard include/*.h include/tsconf/*.h src/*/*.h) $(COMMON_C_HEADERS)
.PHONY: all test clean FORCE
all: $(BUILD)/tsconf.lib $(BUILD)/tsconf.cfg

# Emit absolute CRT and appmake paths for callers that do not include tsconf.mk.
$(BUILD)/tsconf.cfg: config/tsconf.cfg $(ZX_COMMON_ROOT)/config/basic48.cfg Makefile FORCE
	@mkdir -p $(dir $@)
	@sed -e '/^INCLUDE \.\.\/\.\.\/common\/config\/basic48\.cfg$$/d' \
		-e 's|$${ZX_COMMON_ROOT}|$(ZX_COMMON_ROOT)|g' \
		$< $(ZX_COMMON_ROOT)/config/basic48.cfg > $@.tmp
	@cmp -s $@.tmp $@ || mv $@.tmp $@
	@rm -f $@.tmp

$(BUILD)/sources: FORCE
	@mkdir -p $(dir $@)
	@printf '%s\n' $(SOURCES) $(COMMON_ASM) $(COMMON_C) > $@.tmp
	@cmp -s $@.tmp $@ || mv $@.tmp $@
	@rm -f $@.tmp

$(BUILD)/compile-flags: FORCE
	@mkdir -p $(dir $@)
	@printf '%s\n' '$(VIDEO_ASMFLAGS)' '$(CFLAGS)' '$(COMMON_CFLAGS)' > $@.tmp
	@cmp -s $@.tmp $@ || mv $@.tmp $@
	@rm -f $@.tmp

$(BUILD)/%.o: src/%.asm Makefile $(BUILD)/compile-flags $(COMMON_ASM_HEADERS)
	@mkdir -p $(dir $@)
	$(Z80ASM) -mz80 -I$(COMMON_ASM_INCLUDE) $(VIDEO_ASMFLAGS) -o=$@ $<

$(BUILD)/%.o: src/%.c Makefile $(BUILD)/compile-flags $(HEADERS)
	@mkdir -p $(dir $@)
	$(ZCC) $(CFLAGS) -c -o $@ $<

$(BUILD)/common/%.o: ../common/src/%.asm Makefile $(COMMON_ASM_HEADERS)
	@mkdir -p $(dir $@)
	$(Z80ASM) -mz80 -I$(COMMON_ASM_INCLUDE) -o=$@ $<

$(BUILD)/common/%.o: ../common/src/%.c Makefile $(BUILD)/compile-flags $(COMMON_C_HEADERS)
	@mkdir -p $(dir $@)
	$(ZCC) $(COMMON_CFLAGS) -c -o $@ $<

$(BUILD)/tsconf.lib: Makefile $(BUILD)/sources $(OBJECTS) $(COMMON_OBJECTS)
	rm -f $@
	$(Z80ASM) -x=$@ -mz80 $(OBJECTS) $(COMMON_OBJECTS)

ZX_EXAMPLE_FLAGS = $(TSCONF_BASIC48_FLAGS)
ZX_EXAMPLE_DIR := $(CURDIR)/examples/sdk
ZX_EXAMPLE_DEPS := Makefile tsconf.mk $(TSCONF_CFG) $(BUILD)/tsconf.lib \
	$(ZX_APPMAKE_BIN) $(wildcard $(TSCONF_INCLUDE)/*.h $(TSCONF_INCLUDE)/tsconf/*.h)
include $(ZX_COMMON_ROOT)/examples.mk
$(ZX_EXAMPLE_BUILD)/%.tap: TSCONF_BUILD := $(abspath $(BUILD))

test:
	$(MAKE) -C tests test

clean:
ifeq ($(abspath $(BUILD)),$(CURDIR)/build/default)
	$(MAKE) -C tests clean
	rm -rf -- build
else
	rm -rf -- "$(BUILD)"
endif

FORMAT_FILES := $(wildcard *.md config/*.asm examples/sdk/*.c include/*.h include/tsconf/*.h examples/*.md) $(SOURCES)
FORMAT_SUBDIRS := examples/evosdk tests
FORMATTER_ARGS := --dialect=z80asm
include ../../tools/formatter/formatter.mk
