#include <arch/z80.h>
#include <baseconf.h>

#include "bc_case.h"

static uint8_t reject_bd;
static uint8_t reject_be;

/* The emulator exposes both ports. Control which probes succeed at each init. */
uint8_t bc__mem_readback_is_unsafe(bc_readback_backend_t backend) __z88dk_fastcall {
    return backend == BC_READBACK_BD ? reject_bd : reject_be;
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        bc_window_config_t config;
        bc_map_t map = bc_get_active_map();
        ZX_ASSERT(bc_get_readback_backend() == BC_READBACK_BD);
        reject_bd = 1;
        ZX_ASSERT(zx_init() == ZX_OK);
        ZX_ASSERT(bc_get_readback_backend() == BC_READBACK_BE);
        ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_2, 50) == ZX_OK);
        /* Make an unintended cache refresh visible. */
        ZX_ASSERT(bc_set_shadow_ports_override(1) == ZX_OK);
        z80_outp(0xb7f7, (uint8_t)~51u);
        ZX_ASSERT(bc_readback_register((uint8_t)(4u * map + 2u)) == (uint8_t)~51u);
        reject_be = 1;
        ZX_ASSERT(zx_init() == ZX_UNSAFE_CONTEXT);
        ZX_ASSERT(bc_get_readback_backend() == BC_READBACK_BE);
        ZX_ASSERT(bc_get_window_config(map, ZX_WINDOW_2, &config) == ZX_OK &&
                  config.kind == BC_RAM && config.physical_page == 50);
        zx_test_step_marker("rejected_backend");
    }
    zx_test_finish();
    return 0;
}
