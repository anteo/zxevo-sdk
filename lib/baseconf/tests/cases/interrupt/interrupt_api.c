#include <arch/z80.h>
#include <baseconf.h>
#include <string.h>

#include "bc_case.h"

static volatile uint8_t nmi_count;

/* clang-format off */
static void trap_target(void) __naked {
    __asm
        ret
    __endasm;
}
/* clang-format on */

static void install_nmi_handler(void) {
    /* NMI fetches an injected NOP at 0066h, then executes in RAM page FFh.
     * Save AF/BC, increment the resident counter, disarm the trap and RETN. */
    uint8_t handler[] = {0xf5, 0xc5, 0x3a, 0,    0,    0x3c, 0x32, 0,    0,    0x01, 0xbf, 0x00,
                         0xed, 0x78, 0xcb, 0xa7, 0xed, 0x79, 0xc1, 0xf1, 0xd3, 0xbe, 0xed, 0x45};
    uint16_t counter = (uint16_t)(uintptr_t)&nmi_count;
    handler[3] = handler[7] = (uint8_t)counter;
    handler[4] = handler[8] = (uint8_t)(counter >> 8);
    memcpy((void *)0xc067u, handler, sizeof(handler));
}

static void check_nmi(void) {
    bc_execution_trap_t trap = {(uint16_t)(uintptr_t)trap_target, 1};
    uint16_t polls = 0xffffu;
    zx_status_t status = bc_map_ram_page(ZX_WINDOW_3, 0xff);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;
    install_nmi_handler();

    ZX_ASSERT(bc_request_nmi() == ZX_OK);
    while (!nmi_count && --polls) {
    }
    ZX_ASSERT(nmi_count == 1);
    ZX_ASSERT(zx_interrupt_save_disable() == 0);
    zx_test_step_marker("nmi");

    bc_set_execution_trap(trap);
    ZX_ASSERT(bc_readback_register(0x10) == (uint8_t)trap.address);
    ZX_ASSERT(bc_readback_register(0x11) == (uint8_t)(trap.address >> 8));
    ZX_ASSERT((z80_inp(0x00bf) & 0x10) != 0);
    trap_target();
    ZX_ASSERT(nmi_count == 2);
    bc_set_execution_trap(trap);
    ZX_ASSERT(bc_clear_execution_trap() == ZX_OK);
    ZX_ASSERT((z80_inp(0x00bf) & 0x10) == 0);
    ZX_ASSERT(bc_readback_register(0x10) == (uint8_t)trap.address);
    ZX_ASSERT(bc_readback_register(0x11) == (uint8_t)(trap.address >> 8));
    trap_target();
    ZX_ASSERT(nmi_count == 2);
    zx_test_step_marker("trap");
}

int main(void) {
    if (bc_case_init() == ZX_OK) check_nmi();
    zx_test_finish();
    return 0;
}
