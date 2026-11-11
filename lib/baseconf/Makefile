.DEFAULT_GOAL := all
include baseconf.mk
BUILD ?= build/default
CFLAGS := +z80 $(BASECONF_ABI_FLAGS) -D__BASECONF $(BASECONF_INCLUDE_FLAGS) -Isrc
VIDEO_DEFINES := \
	$(addprefix BASECONF_VIDEO_MODE_ENABLED_,$(BASECONF_VIDEO_MODE_SET)) \
	$(addprefix BASECONF_VIDEO_TEXT_,$(BASECONF_VIDEO_TEXT_MODE_SET)) \
	$(addprefix BASECONF_VIDEO_PRIMITIVE_,$(BASECONF_VIDEO_PRIMITIVE_MODE_SET)) \
	$(if $(filter $(BASECONF_VIDEO_GRAPHICS_MODES),$(BASECONF_VIDEO_PRIMITIVE_MODE_SET)),BASECONF_VIDEO_PRIMITIVE_GRAPHICS) \
	$(if $(filter ZX_256 ZX_MULTICOLOR,$(BASECONF_VIDEO_PRIMITIVE_MODE_SET)),BASECONF_VIDEO_PRIMITIVE_ZX_BITMAP) \
	$(if $(filter ZX_256 ZX_MULTICOLOR ATM_640,$(BASECONF_VIDEO_PRIMITIVE_MODE_SET)),BASECONF_VIDEO_PRIMITIVE_BITMAP) \
	$(if $(filter ZX_256 ZX_MULTICOLOR PENTAGON_256,$(BASECONF_VIDEO_PRIMITIVE_MODE_SET)),BASECONF_VIDEO_PRIMITIVE_ZX_OFFSET) \
	$(if $(filter ATM_320 ATM_640,$(BASECONF_VIDEO_PRIMITIVE_MODE_SET)),BASECONF_VIDEO_PRIMITIVE_LINEAR) \
	$(if $(filter PENTAGON_256 ATM_320,$(BASECONF_VIDEO_PRIMITIVE_MODE_SET)),BASECONF_VIDEO_PRIMITIVE_PACKED) \
	$(if $(filter ZX_256 ZX_MULTICOLOR,$(BASECONF_VIDEO_MODE_SET)),BASECONF_VIDEO_MODE_ZX_BITMAP) \
	$(if $(filter PENTAGON_256 ATM_320,$(BASECONF_VIDEO_MODE_SET)),BASECONF_VIDEO_MODE_PACKED) \
	$(if $(filter ZX_256 ZX_MULTICOLOR PENTAGON_256,$(BASECONF_VIDEO_MODE_SET)),BASECONF_VIDEO_MODE_ZX_OFFSET) \
	$(if $(filter ATM_640,$(BASECONF_VIDEO_MODE_SET)),BASECONF_VIDEO_MODE_ATM640) \
	$(if $(filter ATM_320 ATM_640,$(BASECONF_VIDEO_MODE_SET)),BASECONF_VIDEO_MODE_LINEAR) \
	$(if $(strip $(BASECONF_VIDEO_TEXT_MODE_SET)),BASECONF_VIDEO_TEXT_ENABLED) \
	$(if $(filter ATM_TEXT_80 EVO_TEXT_80,$(BASECONF_VIDEO_TEXT_MODE_SET)),BASECONF_VIDEO_TEXT_HARDWARE) \
	$(if $(filter $(BASECONF_VIDEO_GRAPHICS_MODES),$(BASECONF_VIDEO_TEXT_MODE_SET)),BASECONF_VIDEO_TEXT_GRAPHICS) \
	$(if $(filter-out $(BASECONF_VIDEO_TEXT_MODE_SET),$(BASECONF_VIDEO_GRAPHICS_MODES)),BASECONF_VIDEO_TEXT_PARTIAL_GRAPHICS) \
	$(if $(filter ZX_256 ZX_MULTICOLOR,$(BASECONF_VIDEO_TEXT_MODE_SET)),BASECONF_VIDEO_TEXT_ZX_BITMAP) \
	$(if $(filter PENTAGON_256 ATM_320,$(BASECONF_VIDEO_TEXT_MODE_SET)),BASECONF_VIDEO_TEXT_PACKED) \
	$(if $(filter ATM_640,$(BASECONF_VIDEO_TEXT_MODE_SET)),BASECONF_VIDEO_TEXT_ATM640)

ifeq ($(strip $(BASECONF_VIDEO_PRIMITIVE_MODES)),ALL)
VIDEO_DEFINES += BASECONF_VIDEO_PRIMITIVE_ALL
endif
ifeq ($(strip $(BASECONF_VIDEO_TEXT_MODES)|$(BASECONF_VIDEO_PRIMITIVE_MODES)),ALL|ALL)
VIDEO_DEFINES += BASECONF_VIDEO_ALL_MODES
endif
VIDEO_C_DEFINES := $(VIDEO_DEFINES)
ifeq ($(strip $(BASECONF_VIDEO_TEXT_MODES)),ALL)
VIDEO_C_DEFINES += BASECONF_VIDEO_TEXT_ALL
endif
CFLAGS += $(addprefix -D,$(VIDEO_C_DEFINES))
COMMON_ASM_INCLUDE := $(ZX_COMMON_ROOT)/src
ASMFLAGS := -Ca-I$(BASECONF_ROOT)/src -Ca-I$(COMMON_ASM_INCLUDE) $(addprefix -Ca-D,$(VIDEO_DEFINES))
ifeq ($(BASECONF_CONSOLE_NO_DEFAULT_FONT),1)
CFLAGS += -DBASECONF_CONSOLE_NO_DEFAULT_FONT
endif
SOURCES := $(shell find src -type f \( -name '*.c' -o -name '*.asm' \) ! -name baseconf.asm | sort)
C_SOURCES := $(filter %.c,$(SOURCES))
ASM_SOURCES := $(filter %.asm,$(SOURCES))
COMMON_ASM := $(sort $(wildcard ../common/src/*/z80/*.asm))
COMMON_C := $(sort $(wildcard ../common/src/*/c/*.c))
COMMON_OBJECTS := $(patsubst ../common/src/%.asm,$(BUILD)/common/%.o,$(COMMON_ASM)) \
	$(patsubst ../common/src/%.c,$(BUILD)/common/%.o,$(COMMON_C))
COMMON_ASM_HEADERS := $(wildcard $(COMMON_ASM_INCLUDE)/*/z80/*.inc)
COMMON_C_HEADERS := $(wildcard $(ZX_COMMON_ROOT)/include/zx/*.h $(ZX_COMMON_ROOT)/src/*/*.h)
COMMON_CFLAGS := +z80 $(BASECONF_ABI_FLAGS) -I$(ZX_COMMON_ROOT)/include
HEADERS := $(shell find include src -type f \( -name '*.h' -o -name '*.inc' \) | sort)
HEADERS += $(COMMON_C_HEADERS) $(COMMON_ASM_HEADERS)
C_OBJECTS := $(patsubst src/%.c,$(BUILD)/%.o,$(C_SOURCES))
ASM_OBJECTS := $(patsubst src/%.asm,$(BUILD)/asm_%.o,$(ASM_SOURCES))
.PHONY: all clean help FORCE
all: $(BUILD)/baseconf.lib

help:
	@printf '%s\n' \
	  'make [all|examples|appmake|clean|help]' \
	  '  all                       Build baseconf.lib (default)' \
	  '  examples                  Build all BASIC 48 example TAPs' \
	  '  clean                     Remove local library, test and benchmark outputs' \
	  '  appmake                   Build the appmake used to package TAP files' \
	  '  clean                     Remove the current BUILD directory' \
	  '  BUILD                     Archive and object directory (default build/default)' \
	  '  BASECONF_VIDEO_TEXT_MODES       Select text backends (default ALL)' \
	  '  BASECONF_VIDEO_PRIMITIVE_MODES  Select graphics backends (default ALL)' \
	  '  BASECONF_CONSOLE_NO_DEFAULT_FONT=1 excludes the default font.' \
	  '  ZCC and Z80ASM select the z88dk executables.' \
	  'Use make -C tests help or make -C bench help for tests and benchmarks.'

$(BUILD):
	mkdir -p $@

$(BUILD)/baseconf.sources: FORCE | $(BUILD)
	@printf '%s\n' $(SOURCES) $(COMMON_ASM) $(COMMON_C) > $@.tmp
	@cmp -s $@.tmp $@ || mv $@.tmp $@
	@rm -f $@.tmp

# All compile-time options share one stamp, so changing any profile setting
# rebuilds objects without keeping a list of affected source files here.
$(BUILD)/compile-flags: FORCE | $(BUILD)
	@printf '%s\n' '$(CFLAGS)' '$(ASMFLAGS)' '$(COMMON_CFLAGS)' > $@.tmp
	@cmp -s $@.tmp $@ || mv $@.tmp $@
	@rm -f $@.tmp

$(BUILD)/%.o: src/%.c $(HEADERS) baseconf.mk $(BUILD)/compile-flags | $(BUILD)
	@mkdir -p $(dir $@)
	$(ZCC) $(CFLAGS) -c -o $@ $<

$(BUILD)/asm_%.o: src/%.asm $(HEADERS) baseconf.mk $(BUILD)/compile-flags | $(BUILD)
	@mkdir -p $(dir $@)
	$(ZCC) $(CFLAGS) $(ASMFLAGS) -c -o $@ $<

$(BUILD)/common/%.o: ../common/src/%.asm Makefile $(COMMON_ASM_HEADERS)
	@mkdir -p $(dir $@)
	$(Z80ASM) -mz80 -I$(COMMON_ASM_INCLUDE) -o=$@ $<

$(BUILD)/common/%.o: ../common/src/%.c Makefile $(COMMON_C_HEADERS) $(BUILD)/compile-flags
	@mkdir -p $(dir $@)
	$(ZCC) $(COMMON_CFLAGS) -c -o $@ $<

$(BUILD)/baseconf.lib: Makefile baseconf.mk $(BUILD)/baseconf.sources $(C_OBJECTS) $(ASM_OBJECTS) $(COMMON_OBJECTS)
	rm -f $@
	$(Z80ASM) -x=$@ -m=z80 $(C_OBJECTS) $(ASM_OBJECTS) $(COMMON_OBJECTS)

ZX_EXAMPLE_FLAGS = $(BASECONF_BASIC48_FLAGS)
ZX_EXAMPLE_DEPS := Makefile baseconf.mk $(BASECONF_CFG) $(BUILD)/baseconf.lib \
	$(ZX_APPMAKE_BIN) $(wildcard $(BASECONF_INCLUDE)/*.h $(BASECONF_INCLUDE)/baseconf/*.h)
include $(ZX_COMMON_ROOT)/examples.mk
$(ZX_EXAMPLE_BUILD)/%.tap: BASECONF_BUILD := $(abspath $(BUILD))

clean:
ifeq ($(abspath $(BUILD)),$(CURDIR)/build/default)
	$(MAKE) -C tests clean
	$(MAKE) -C bench clean
	rm -rf -- build
else
	rm -rf -- "$(BUILD)"
endif

# Shared formatting targets: all library sources participate, not only the
# ones linked into the default archive. One list, rules come from extensions.
FORMAT_FILES := $(wildcard *.md examples/*.c) $(shell find src include config -type f \( -name '*.c' -o -name '*.h' -o -name '*.asm' -o -name '*.inc' \))
FORMAT_SUBDIRS := bench tests
FORMATTER_ARGS := --dialect=z80asm
include ../../tools/formatter/formatter.mk
