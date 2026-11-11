.DEFAULT_GOAL := all

.PHONY: all baseconf-lib tsconf-lib examples examples-baseconf examples-tsconf test test-baseconf test-tsconf test-common clean

all: baseconf-lib tsconf-lib

baseconf-lib:
	$(MAKE) -C lib/baseconf all

tsconf-lib:
	$(MAKE) -C lib/tsconf all

examples: examples-baseconf examples-tsconf

examples-baseconf:
	$(MAKE) -C lib/baseconf examples

examples-tsconf:
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

clean:
	$(MAKE) -C lib clean
	$(MAKE) -C tools/appmake clean
	find . \( -name .git -o -name build -o -name out \) -prune -o \
	  -type d -name __pycache__ -prune -exec rm -rf -- {} +

FORMAT_FILES := README.md README.ru.md $(wildcard tools/formatter/*.md)
FORMAT_SUBDIRS := lib tools/appmake
include tools/formatter/formatter.mk
