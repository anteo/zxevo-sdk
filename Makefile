.DEFAULT_GOAL := all

.PHONY: all baseconf-lib tsconf-lib examples examples-baseconf examples-tsconf test test-baseconf test-tsconf test-common test-appmake release clean

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

test:
	$(MAKE) test-baseconf
	$(MAKE) test-tsconf
	$(MAKE) test-common

test-baseconf:
	$(MAKE) -C lib/baseconf/tests test

test-tsconf:
	$(MAKE) -C lib/tsconf/tests test

test-common:
	$(MAKE) -C lib/common/tests test

test-appmake:
	@mkdir -p tools/appmake/build/tests
	@$(MAKE) --no-print-directory -C tools/appmake test 2>tools/appmake/build/tests/make.log

release: export SDK_RELEASE_VERSION := $(VERSION)
release:
	@tools/versioning/release.sh "$$SDK_RELEASE_VERSION"

clean:
	$(MAKE) -C lib clean
	$(MAKE) -C tools/appmake clean
	find . \( -name .git -o -name build -o -name out \) -prune -o \
	  -type d -name __pycache__ -prune -exec rm -rf -- {} +

include tools/appmake/appmake.mk

FORMAT_FILES := README.md README.ru.md $(wildcard tools/formatter/*.md tools/profiling/*.md tools/test_runner/*.md)
FORMAT_SUBDIRS := lib tools/appmake
include tools/formatter/formatter.mk
