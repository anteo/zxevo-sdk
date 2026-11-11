# Applications opt in by depending on the host tool when they package a TAP.
ifndef ZX_APPMAKE_MK_INCLUDED
ZX_APPMAKE_MK_INCLUDED := 1
ZX_APPMAKE_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
ZX_APPMAKE_BIN := $(ZX_APPMAKE_DIR)/build/z88dk-appmake

ifeq ($(strip $(Z88DK_SRC)),)
ifneq ($(strip $(ZCCCFG)),)
Z88DK_SRC := $(abspath $(ZCCCFG)/../../src)
endif
endif

ZX_APPMAKE_DEFAULT_GOAL := $(.DEFAULT_GOAL)
.PHONY: appmake
appmake: $(ZX_APPMAKE_BIN)

$(ZX_APPMAKE_BIN): $(addprefix $(ZX_APPMAKE_DIR)/,Makefile build.sh zxevo.c patches/zxevo-registration.patch)
	$(MAKE) -C "$(ZX_APPMAKE_DIR)" Z88DK_SRC="$(Z88DK_SRC)"

.DEFAULT_GOAL := $(ZX_APPMAKE_DEFAULT_GOAL)
endif
