#include <arch/z80.h>
#include <baseconf.h>

#include "bc_case.h"

static uint8_t rejected_probes;
static bc_readback_backend_t selected_during_probe;

/* Substitute a failing BE probe even when the emulator exposes both ports. */
uint8_t bc__mem_readback_is_unsafe(bc_readback_backend_t backend) __z88dk_fastcall {
    if (backend == BC_READBACK_BD) return 0;
    ++rejected_probes;
    selected_during_probe = bc_get_readback_backend();
    return 1;
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        bc_window_config_t config;
        bc_map_t map = bc_get_active_map();
        ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_2, 50) == ZX_OK);
        /* Make an unintended cache refresh visible. */
        ZX_ASSERT(bc_set_shadow_ports_override(1) == ZX_OK);
        z80_outp(0xb7f7, (uint8_t)~51u);
        ZX_ASSERT(bc_readback_register((uint8_t)(4u * map + ZX_WINDOW_2)) == (uint8_t)~51u);
        ZX_ASSERT(bc_set_readback_backend(BC_READBACK_BE) == ZX_UNSAFE_CONTEXT);
        ZX_ASSERT(rejected_probes == 1 && selected_during_probe == BC_READBACK_BD);
        ZX_ASSERT(bc_get_readback_backend() == BC_READBACK_BD);
        ZX_ASSERT(bc_get_window_config(map, ZX_WINDOW_2, &config) == ZX_OK &&
                  config.kind == BC_RAM && config.physical_page == 50);
        zx_test_step_marker("rejected_backend");
    }
    zx_test_finish();
    return 0;
}
