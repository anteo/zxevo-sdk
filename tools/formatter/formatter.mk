# Shared formatting targets for ZX Evolution projects.
#
# The project lists the sources it wants formatted and includes this fragment
# at the end of its Makefile:
#
#   FORMAT_FILES   := $(wildcard src/*.c src/*.h src/*.asm)
#   FORMATTER_ARGS := --dialect=z80asm    # optional, forwarded by extension
#   include ../tools/formatter/formatter.mk
#
# The dispatcher routes local files by extension. FORMAT_SUBDIRS optionally
# forwards the target to component Makefiles with their own file lists.
#
# Targets provided here: format, format-check, format-plan.

# Resolve the dispatcher relative to this included file, not to the caller.
# It finds the built-in formatters next to itself, so no mapping is needed.
FORMATTER_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
FORMATTER ?= $(FORMATTER_DIR)/formatter

# Dispatcher arguments, empty by default. They reach only the formatters that
# declare them, for example --dialect=z80asm or --clang-format=/opt/clang.
FORMATTER_ARGS ?=

FORMAT_CMD = $(FORMATTER) $(FORMATTER_ARGS)
FORMAT_RECURSE = $(foreach dir,$(FORMAT_SUBDIRS),$(MAKE) -C "$(dir)" $@ &&) :

# The first target of an included file silently becomes the default goal, so
# remember the caller's goal here and restore it at the end of this file.
FORMATTER_DEFAULT_GOAL := $(.DEFAULT_GOAL)

.PHONY: format format-check format-plan

format-check: FORMAT_CHECK_FLAG := --check
format format-check:
	$(if $(strip $(FORMAT_FILES)),$(FORMAT_CMD) $(FORMAT_CHECK_FLAG) $(FORMAT_FILES),@:)
	+@$(FORMAT_RECURSE)

format-plan:
	@printf 'formatter: %s\n' '$(FORMATTER)'
	$(if $(strip $(FORMAT_FILES)),@printf '  %s\n' $(FORMAT_FILES),@:)
	+@$(FORMAT_RECURSE)

# Restore the default goal so `make` without arguments still does what the
# project expects; the fragment may be included anywhere in the Makefile.
ifneq ($(FORMATTER_DEFAULT_GOAL),)
.DEFAULT_GOAL := $(FORMATTER_DEFAULT_GOAL)
endif
