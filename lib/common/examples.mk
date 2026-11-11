# Build each standalone C example with the including library's BASIC 48 profile.
ZX_EXAMPLES_MK := $(lastword $(MAKEFILE_LIST))
ZX_EXAMPLE_DIR := $(CURDIR)/examples
ZX_EXAMPLE_BUILD := $(CURDIR)/build/examples
ZX_EXAMPLE_SOURCES := $(wildcard $(ZX_EXAMPLE_DIR)/*.c)
ZX_EXAMPLE_TAPS := $(patsubst $(ZX_EXAMPLE_DIR)/%.c,$(ZX_EXAMPLE_BUILD)/%.tap,$(ZX_EXAMPLE_SOURCES))
ZX_EXAMPLE_INPUTS := $(ZX_EXAMPLES_MK) $(ZX_COMMON_ROOT)/config/basic48.cfg \
	$(ZX_COMMON_ROOT)/crt/basic48_crt0.asm $(ZX_COMMON_ROOT)/crt/crt_stdio.inc \
	$(ZX_COMMON_ROOT)/crt/crt_zx_lifecycle.inc \
	$(wildcard $(ZX_COMMON_ROOT)/include/zx/*.h $(ZX_EXAMPLE_DIR)/*.h)

.PHONY: examples
examples: $(ZX_EXAMPLE_TAPS)

# Rebuild the TAPs when the application flags change, including back to defaults.
$(ZX_EXAMPLE_BUILD)/compile-flags: FORCE
	@mkdir -p $(dir $@)
	@printf '%s\n' '$(subst ','"'"',$(ZX_EXAMPLE_FLAGS) $(ZX_EXAMPLE_EXTRA_FLAGS))' > $@.tmp
	@cmp -s $@.tmp $@ || mv $@.tmp $@
	@rm -f $@.tmp

$(ZX_EXAMPLE_BUILD)/%.tap: $(ZX_EXAMPLE_DIR)/%.c $(ZX_EXAMPLE_INPUTS) $(ZX_EXAMPLE_DEPS) $(ZX_EXAMPLE_BUILD)/compile-flags
	@mkdir -p $(dir $@)
	$(ZCC) $(ZX_EXAMPLE_FLAGS) $(ZX_EXAMPLE_EXTRA_FLAGS) -m -create-app -Cz--blockname="$*" -o $(basename $@) $<
