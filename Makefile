.DEFAULT_GOAL := all

.PHONY: all baseconf-lib tsconf-lib examples examples-baseconf examples-tsconf examples-evosdk examples-xnx test test-baseconf test-tsconf test-common test-appmake release clean

all: baseconf-lib tsconf-lib

baseconf-lib:
	$(MAKE) -C lib/baseconf all

tsconf-lib:
	$(MAKE) -C lib/tsconf all

examples: examples-baseconf examples-tsconf

examples-baseconf: appmake
	$(MAKE) -C lib/baseconf examples

examples-tsconf: appmake
	$(MAKE) -C lib/tsconf examples

# Asset recipes prepare Python dependencies automatically; z88dk-zx0 is required.
examples-evosdk: appmake
	$(MAKE) -C lib/tsconf/examples/evosdk all

examples-xnx: appmake
	$(MAKE) -C lib/tsconf/examples/evosdk/xnx all

test:
	@status=0; \
	for suite in test-baseconf test-tsconf test-common; do \
		$(MAKE) --no-print-directory "$$suite" || status=1; \
	done; \
	exit $$status

test-baseconf:
	@$(MAKE) --no-print-directory -C lib/baseconf/tests test

test-tsconf:
	@$(MAKE) --no-print-directory -C lib/tsconf/tests test

test-common:
	@$(MAKE) --no-print-directory -C lib/common/tests test

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
	$(MAKE) -C lib/tsconf/examples/evosdk/xnx clean
	$(MAKE) -C tools/appmake clean
	$(MAKE) -C tools/mhmt clean
	rm -rf -- build tools/assets/build
	find . \( -name .git -o -name build -o -name out \) -prune -o \
	  -type d -name __pycache__ -prune -exec rm -rf -- {} +

include tools/appmake/appmake.mk

FORMAT_FILES := README.md README.ru.md $(wildcard tools/assets/*.md tools/formatter/*.md tools/mhmt/*.md tools/profiling/*.md tools/python/*.md tools/screenshots/*.md tools/test_runner/*.md)
FORMAT_SUBDIRS := lib tools/appmake
include tools/formatter/formatter.mk
