CC ?= cc
BUILD := build
SOURCES := $(addprefix src/mhmt-,emit.c globals.c hash.c lz.c main.c optimal.c pack.c parsearg.c tb.c depack.c)
HEADERS := $(wildcard src/*.h)

.DEFAULT_GOAL := all
.PHONY: all clean
all: $(BUILD)/mhmt

$(BUILD)/mhmt: $(SOURCES) $(HEADERS) Makefile
	mkdir -p $(BUILD)
	$(CC) -std=c99 -O2 -D_POSIX_C_SOURCE=1 $(SOURCES) -o $@

clean:
	rm -rf $(BUILD)
