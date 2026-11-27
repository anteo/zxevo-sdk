.DEFAULT_GOAL := all

SDK_ROOT := $(abspath ..)
PYTHON ?= python3
ZESARUX_UPSTREAM ?= $(SDK_ROOT)/upstream/zesarux
ZESARUX_REV ?= HEAD
ZESARUX_CONFIGURE_FLAGS ?= --disable-xwindows --disable-sdl
ZESARUX_BUILD_DIR ?= $(CURDIR)/build
SOURCE := $(ZESARUX_BUILD_DIR)/source

PATCH_DIRS := patches/audio patches/video patches/zxevo patches/test-fixes patches/menu

.PHONY: all prepare clean
all: prepare
	cd "$(SOURCE)/src" && if [ ! -f Makefile ]; then \
	  ./configure $(ZESARUX_CONFIGURE_FLAGS) || { rm -f Makefile; exit 1; }; \
	fi
	$(MAKE) -C "$(SOURCE)/src"

prepare:
ifneq ($(ROM),)
	@test -f "$(ROM)" || { printf 'ROM file not found: %s\n' "$(ROM)" >&2; exit 1; }
endif
ifneq ($(SKIP_SUBMODULES),1)
ifeq ($(abspath $(ZESARUX_UPSTREAM)),$(SDK_ROOT)/upstream/zesarux)
	git -C "$(SDK_ROOT)" submodule update --init -- upstream/zesarux
endif
endif
	$(PYTHON) "$(SDK_ROOT)/tools/upstream/prepare.py" \
	  --repository "$(ZESARUX_UPSTREAM)" --revision "$(ZESARUX_REV)" --destination "$(SOURCE)" \
	  --patch-dir $(PATCH_DIRS) $(if $(ZESARUX_EXTRA_PATCH_DIR),"$(ZESARUX_EXTRA_PATCH_DIR)") \
	  --config "configure=$(ZESARUX_CONFIGURE_FLAGS)" "rom=$(if $(ROM),custom,upstream)" \
	  $(if $(ZESARUX_OVERLAY_DIR),--overlay-dir "$(ZESARUX_OVERLAY_DIR)")
ifneq ($(ROM),)
	cp "$(ROM)" "$(SOURCE)/src/zxevo_baseconf.rom"
	cp "$(ROM)" "$(SOURCE)/src/zxevo_tsconf.rom"
endif

clean:
	rm -rf -- "$(SOURCE)"
