# Shared BaseConf/z88dk build paths and ABI/tool settings.
BASECONF_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
export BASECONF_ROOT
export ZX_COMMON_ROOT := $(abspath $(BASECONF_ROOT)/../common)

# Video mode families compiled into BaseConf. Values may be ALL, GRAPHICS,
# NONE, or a whitespace-separated list of mode names from the list below.
# Keep these as build settings (rather than API settings): changing them
# changes the objects and requires a matching baseconf.lib build.
BASECONF_VIDEO_ALL_MODES := ZX_256 ZX_MULTICOLOR PENTAGON_256 ATM_320 ATM_640 ATM_TEXT_80 EVO_TEXT_80
BASECONF_VIDEO_GRAPHICS_MODES := ZX_256 ZX_MULTICOLOR PENTAGON_256 ATM_320 ATM_640
BASECONF_VIDEO_ALL_PRIMITIVE_MODES := $(BASECONF_VIDEO_GRAPHICS_MODES)
BASECONF_VIDEO_TEXT_MODES ?= ALL
BASECONF_VIDEO_PRIMITIVE_MODES ?= ALL

empty :=
space := $(empty) $(empty)
bc_video_resolve_modes = $(if $(filter ALL,$(strip $(1))),$(2),$(if $(filter GRAPHICS,$(strip $(1))),$(BASECONF_VIDEO_GRAPHICS_MODES),$(if $(filter NONE,$(strip $(1))),,$(strip $(1)))))
BASECONF_VIDEO_TEXT_MODE_SET := $(call bc_video_resolve_modes,$(BASECONF_VIDEO_TEXT_MODES),$(BASECONF_VIDEO_ALL_MODES))
BASECONF_VIDEO_PRIMITIVE_MODE_SET := $(call bc_video_resolve_modes,$(BASECONF_VIDEO_PRIMITIVE_MODES),$(BASECONF_VIDEO_ALL_PRIMITIVE_MODES))
BASECONF_VIDEO_MODE_SET := $(sort $(BASECONF_VIDEO_TEXT_MODE_SET) $(BASECONF_VIDEO_PRIMITIVE_MODE_SET))

BASECONF_VIDEO_VALID_MODES := $(BASECONF_VIDEO_ALL_MODES) ALL GRAPHICS NONE
BASECONF_VIDEO_INVALID_TEXT_MODES := $(filter-out $(BASECONF_VIDEO_VALID_MODES),$(strip $(BASECONF_VIDEO_TEXT_MODES)))
BASECONF_VIDEO_INVALID_PRIMITIVE_MODES := $(filter-out $(BASECONF_VIDEO_VALID_MODES),$(strip $(BASECONF_VIDEO_PRIMITIVE_MODES)))
ifneq ($(strip $(BASECONF_VIDEO_INVALID_TEXT_MODES)),)
$(error Unknown mode(s) in BASECONF_VIDEO_TEXT_MODES: $(BASECONF_VIDEO_INVALID_TEXT_MODES))
endif
ifneq ($(strip $(BASECONF_VIDEO_INVALID_PRIMITIVE_MODES)),)
$(error Unknown mode(s) in BASECONF_VIDEO_PRIMITIVE_MODES: $(BASECONF_VIDEO_INVALID_PRIMITIVE_MODES))
endif

ZCC ?= zcc
Z80ASM ?= z88dk-z80asm
# z80asm reads Z80ASM from the environment as extra assembler options. Keep
# this Make variable available to recipes but prevent make from exporting the
# executable path into zcc/z80asm's options channel.
unexport Z80ASM

BASECONF_CFG ?= $(BASECONF_ROOT)/config/baseconf.cfg
BASECONF_CRT_INPUTS := $(BASECONF_CFG) $(BASECONF_ROOT)/config/baseconf_crt0.asm \
	$(ZX_COMMON_ROOT)/z80_crt0.asm $(ZX_COMMON_ROOT)/crt_no_stdio.inc \
	$(ZX_COMMON_ROOT)/crt_zx_lifecycle.inc
BASECONF_INCLUDE ?= $(BASECONF_ROOT)/include
BASECONF_INCLUDE_FLAGS = -I$(BASECONF_INCLUDE) -I$(ZX_COMMON_ROOT)/include
BASECONF_BUILD ?= $(BASECONF_ROOT)/build/default
BASECONF_LIB ?= $(BASECONF_BUILD)/baseconf.lib
BASECONF_APPMAKE_BIN ?= $(abspath $(BASECONF_ROOT)/../../tools/appmake/build/z88dk-appmake)
BASECONF_ABI_FLAGS ?= -clib=classic -compiler=sdcc --reserve-regs-iy
BASECONF_APP_FLAGS = +$(BASECONF_CFG) $(BASECONF_ABI_FLAGS) $(BASECONF_INCLUDE_FLAGS) -L$(BASECONF_BUILD)
BASECONF_BASIC48_FLAGS = $(BASECONF_APP_FLAGS) -subtype=basic48

ifeq ($(strip $(Z88DK_ROOT)),)
ifneq ($(strip $(ZCCCFG)),)
Z88DK_ROOT := $(abspath $(ZCCCFG)/../..)
endif
endif
ifeq ($(strip $(Z88DK_SRC)),)
ifneq ($(strip $(ZCCCFG)),)
Z88DK_SRC := $(abspath $(ZCCCFG)/../../src)
endif
endif

BASECONF_LIBRARY_INPUTS := $(BASECONF_ROOT)/Makefile $(BASECONF_ROOT)/baseconf.mk \
	$(wildcard $(ZX_COMMON_ROOT)/src/*/z80/*.asm $(ZX_COMMON_ROOT)/src/*/z80/*.inc) \
	$(wildcard $(ZX_COMMON_ROOT)/src/*/c/*.c $(ZX_COMMON_ROOT)/src/*/*.h) \
	$(wildcard $(ZX_COMMON_ROOT)/include/zx/*.h) \
	$(shell find $(BASECONF_ROOT)/src $(BASECONF_ROOT)/include -type f \( -name '*.c' -o -name '*.asm' -o -name '*.h' -o -name '*.inc' \) | sort)

# Consumers that package TAP applications opt into this rule. The library's
# default archive target has no dependency on appmake or its external sources.
.PHONY: baseconf-appmake
baseconf-appmake: $(BASECONF_APPMAKE_BIN)

$(BASECONF_APPMAKE_BIN): $(BASECONF_ROOT)/../../tools/appmake/Makefile \
		$(BASECONF_ROOT)/../../tools/appmake/build.sh \
		$(BASECONF_ROOT)/../../tools/appmake/baseconf.c \
		$(BASECONF_ROOT)/../../tools/appmake/patches/baseconf-registration.patch
	$(MAKE) -C $(BASECONF_ROOT)/../../tools/appmake Z88DK_SRC="$(Z88DK_SRC)"
