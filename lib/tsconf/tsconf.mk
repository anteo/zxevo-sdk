# Shared z88dk settings for TSConf applications and library builds.
TSCONF_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
export ZX_COMMON_ROOT := $(abspath $(TSCONF_ROOT)/../common)

ZCC ?= zcc
Z80ASM ?= z88dk-z80asm
# z80asm interprets the environment variable of the same name as options.
unexport Z80ASM

TSCONF_CFG ?= $(TSCONF_ROOT)/config/tsconf.cfg
TSCONF_INCLUDE ?= $(TSCONF_ROOT)/include
TSCONF_BUILD ?= $(TSCONF_ROOT)/build/default
TSCONF_LIB ?= $(TSCONF_BUILD)/tsconf.lib
TSCONF_ABI_FLAGS ?= -clib=classic -compiler=sdcc --reserve-regs-iy

TSCONF_APP_FLAGS = +$(TSCONF_CFG) $(TSCONF_ABI_FLAGS) -I$(TSCONF_INCLUDE) -I$(ZX_COMMON_ROOT)/include -L$(TSCONF_BUILD)
TSCONF_BASIC48_FLAGS = $(TSCONF_APP_FLAGS) -subtype=basic48
