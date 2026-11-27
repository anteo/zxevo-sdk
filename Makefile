.DEFAULT_GOAL := all

.PHONY: all submodules baseconf-lib tsconf-lib examples examples-all examples-baseconf examples-tsconf examples-evosdk examples-xnx emulator test test-appmake release clean

PYTHON ?= python3
SUITE ?= all
CASE ?=

all: baseconf-lib tsconf-lib

submodules:
	git submodule update --init --recursive

baseconf-lib:
	$(MAKE) -C lib/baseconf all

tsconf-lib:
	$(MAKE) -C lib/tsconf all

examples: examples-baseconf examples-tsconf

# The three groups build the same TSConf archive. Finish each before starting the next.
examples-all: examples
	$(MAKE) examples-evosdk
	$(MAKE) examples-xnx

examples-baseconf: appmake
	$(MAKE) -C lib/baseconf examples

examples-tsconf: appmake
	$(MAKE) -C lib/tsconf examples

# Asset recipes prepare Python dependencies automatically; z88dk-zx0 is required.
examples-evosdk: appmake
	$(MAKE) -C lib/tsconf/examples/evosdk all

examples-xnx: appmake
	$(MAKE) -C lib/tsconf/examples/xnx all

emulator:
	$(MAKE) -C zesarux $(if $(ROM),ROM="$(abspath $(ROM))") \
	  $(if $(ZESARUX_BUILD_DIR),ZESARUX_BUILD_DIR="$(abspath $(ZESARUX_BUILD_DIR))") \
	  $(if $(ZESARUX_EXTRA_PATCH_DIR),ZESARUX_EXTRA_PATCH_DIR="$(abspath $(ZESARUX_EXTRA_PATCH_DIR))") \
	  $(if $(ZESARUX_OVERLAY_DIR),ZESARUX_OVERLAY_DIR="$(abspath $(ZESARUX_OVERLAY_DIR))") \
	  $(if $(ZESARUX_UPSTREAM),ZESARUX_UPSTREAM="$(abspath $(ZESARUX_UPSTREAM))")

test: export ZX_TEST_SUITE := $(strip $(SUITE))
test: export ZX_TEST_CASE := $(strip $(CASE))
test: export ZX_TEST_JOBS := $(strip $(JOBS))
test:
	@$(PYTHON) tools/test_runner/runner.py "$$ZX_TEST_SUITE" check \
		$(if $(strip $(JOBS)),--jobs "$$ZX_TEST_JOBS") \
		$(if $(strip $(CASE)),--case "$$ZX_TEST_CASE") \
		$(if $(filter 1,$(FAIL_FAST)),--fail-fast) $(if $(filter 1,$(RERUN_FAILED)),--rerun-failed) \
		$(if $(filter 1,$(CONTINUE)),--continue)

test-appmake:
	@mkdir -p tools/appmake/build/tests
	@$(MAKE) --no-print-directory -C tools/appmake test 2>tools/appmake/build/tests/make.log

release: export SDK_RELEASE_VERSION := $(VERSION)
release: export SDK_RELEASE_MAKE := $(MAKE)
release:
	@tools/versioning/release.sh "$$SDK_RELEASE_VERSION"

clean:
	$(MAKE) -C lib clean
	$(MAKE) -C lib/tsconf/examples/evosdk clean
	$(MAKE) -C lib/tsconf/examples/xnx clean
	$(MAKE) -C tools/appmake clean
	$(MAKE) -C tools/mhmt clean
	$(MAKE) -C zesarux clean $(if $(ZESARUX_BUILD_DIR),ZESARUX_BUILD_DIR="$(abspath $(ZESARUX_BUILD_DIR))")
	rm -rf -- build tools/assets/build
	find . \( -name .git -o -path ./upstream -o -name build -o -name out \) -prune -o \
	  -type d -name __pycache__ -prune -exec rm -rf -- {} +

include tools/appmake/appmake.mk

FORMAT_FILES := README.md README.ru.md $(wildcard tools/assets/*.md tools/formatter/*.md tools/mhmt/*.md tools/profiling/*.md tools/python/*.md tools/screenshots/*.md tools/test_runner/*.md)
FORMAT_SUBDIRS := lib tools/appmake
include tools/formatter/formatter.mk
