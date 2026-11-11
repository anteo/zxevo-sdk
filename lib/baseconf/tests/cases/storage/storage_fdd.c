#include <arch/z80.h>
#include <baseconf.h>

#include "bc_case.h"

static void check_overlay(void) {
    uint8_t initial, mask, value = 0x5a;
    zx_status_t status = bc_fdd_overlay_get(&initial);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;
    ZX_ASSERT(bc_fdd_overlay_probe() == ZX_OK);
    ZX_ASSERT(bc_fdd_overlay_get(&mask) == ZX_OK && mask == initial);
    ZX_ASSERT(bc_fdd_overlay_set(0x10) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(bc_fdd_overlay_set(2) == ZX_OK);
    ZX_ASSERT(bc_fdd_overlay_get(&mask) == ZX_OK && mask == 2);
    ZX_ASSERT(zx_fdd_reg_read(ZX_FDD_TRACK, &value) == ZX_UNSAFE_CONTEXT);
    ZX_ASSERT(value == 0x5a);
    ZX_ASSERT(zx_fdd_reg_write(ZX_FDD_SECTOR, 1) == ZX_UNSAFE_CONTEXT);
    ZX_ASSERT(bc_fdd_overlay_set(initial) == ZX_OK);
    ZX_ASSERT(bc_fdd_overlay_get(&mask) == ZX_OK && mask == initial);
    zx_test_step_marker("overlay");
}

static void check_system_port(void) {
    const zx_fdd_system_t system = {ZX_FDD_DRIVE_C, 1, 1, 0};
    uint8_t bf = z80_inp(0x00bf);
    uint8_t config = bc_readback_register(0x0c);
    uint8_t status;
    ZX_ASSERT(zx_fdd_system_write(&system) == ZX_OK);
    ZX_ASSERT(zx_fdd_status(&status) == ZX_OK && (status & 0x1f) == 0x1e);
    ZX_ASSERT(bc_fdd_select(ZX_FDD_DRIVE_D) == ZX_OK);
    ZX_ASSERT(zx_fdd_status(&status) == ZX_OK && (status & 3) == ZX_FDD_DRIVE_D);
    ZX_ASSERT(z80_inp(0x00bf) == bf);
    ZX_ASSERT(bc_readback_register(0x0c) == config);
    zx_test_step_marker("system_port");
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        check_overlay();
        check_system_port();
    }
    zx_test_finish();
    return 0;
}
