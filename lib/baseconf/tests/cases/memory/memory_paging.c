#include <arch/z80.h>
#include <baseconf.h>

#include "bc_case.h"

enum {
    PORT_PAGING = 0x7ffd,
    PORT_SHADOW = 0x00bf,
    PORT_W2_RAM = 0xb7f7,
    REG_PAGING = 0x0a,
    REG_ADDRESSING = 0x0b,
    REG_SYSTEM = 0x0c,
    ADDRESSING_128K = 0x04,
};

static volatile uint8_t *const probe = (volatile uint8_t *)0x8123u;

static void check_readback(void) {
    bc_paging_snapshot_t snapshot;
    uint8_t paging = bc_readback_register(REG_PAGING);
    uint8_t eff7 = bc_readback_register(REG_ADDRESSING);
    uint8_t system = bc_readback_register(REG_SYSTEM);
    uint16_t port = 0x3c77u;
    if (system & 0x80u) port |= 0x4000u;
    if (system & 0x40u) port |= 0x0200u;
    if (system & 0x20u) port |= 0x0100u;

    ZX_ASSERT(bc_get_paging_state(&snapshot) == ZX_OK);
    ZX_ASSERT(snapshot.saved_7ffd == paging && snapshot.saved_eff7 == eff7);
    ZX_ASSERT(snapshot.saved_xx77_data == (system & 0x0fu));
    ZX_ASSERT(snapshot.saved_xx77_address == port);
    ZX_ASSERT(bc_get_paging_state(0) == ZX_INVALID_ARGUMENT);

    ZX_ASSERT(bc_get_readback_backend() == BC_READBACK_BD);
    ZX_ASSERT(bc_set_readback_backend(BC_READBACK_BE) == ZX_OK);
    ZX_ASSERT(bc_get_readback_backend() == BC_READBACK_BE);
    ZX_ASSERT(bc_readback_register(REG_PAGING) == paging);
    ZX_ASSERT(bc_readback_register(REG_ADDRESSING) == eff7);
    ZX_ASSERT(bc_readback_register(REG_SYSTEM) == system);
    ZX_ASSERT(bc_set_readback_backend((bc_readback_backend_t)2) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(bc_get_readback_backend() == BC_READBACK_BE);
    ZX_ASSERT(bc_set_readback_backend(BC_READBACK_BD) == ZX_OK);
    zx_test_step_marker("readback");
}

static void check_resync(void) {
    bc_map_t map = bc_get_active_map();
    uint8_t shadow = BC_CONFIG_SHADOW_PORTS(z80_inp(PORT_SHADOW));
    bc_window_config_t config;

    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_2, 50) == ZX_OK);
    *probe = 0xa7;
    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_2, 51) == ZX_OK);
    *probe = 0x53;
    ZX_ASSERT(bc_set_shadow_ports_override(1) == ZX_OK);
    ZX_ASSERT(BC_CONFIG_SHADOW_PORTS(z80_inp(PORT_SHADOW)) != 0);
    z80_outp(PORT_W2_RAM, (uint8_t)~50u);
    ZX_ASSERT(*probe == 0xa7);
    ZX_ASSERT(bc_get_window_config(map, ZX_WINDOW_2, &config) == ZX_OK);
    ZX_ASSERT(config.physical_page == 51);
    ZX_ASSERT(bc_resync() == ZX_OK);
    ZX_ASSERT(bc_get_window_config(map, ZX_WINDOW_2, &config) == ZX_OK);
    ZX_ASSERT(config.kind == BC_RAM && config.physical_page == 50);
    ZX_ASSERT(bc_set_shadow_ports_override(0) == ZX_OK);
    ZX_ASSERT(BC_CONFIG_SHADOW_PORTS(z80_inp(PORT_SHADOW)) == 0);
    ZX_ASSERT(bc_set_shadow_ports_override(shadow) == ZX_OK);
    zx_test_step_marker("resync");
}

static void check_addressing(void) {
    uint8_t original_paging = bc_readback_register(REG_PAGING);
    uint8_t eff7 = bc_readback_register(REG_ADDRESSING);
    bc_addressing_t original = eff7 & ADDRESSING_128K ? BC_ADDRESSING_128K : BC_ADDRESSING_1024K;
    bc_map_t map = BC_PAGING_ACTIVE_MAP(original_paging);
    const bc_window_config_t substituted = {BC_RAM, 8, 1, 0};
    bc_window_config_t config;

    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_2, 2) == ZX_OK);
    *probe = 0x24;
    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_2, 10) == ZX_OK);
    *probe = 0xa9;
    ZX_ASSERT(bc_configure_window(map, ZX_WINDOW_2, &substituted) == ZX_OK);
    ZX_ASSERT(bc_set_addressing(BC_ADDRESSING_1024K) == ZX_OK);
    z80_outp(PORT_PAGING, (uint8_t)((original_paging & 0x18u) | 2u));
    ZX_ASSERT(bc_readback_register(REG_ADDRESSING) == (eff7 & (uint8_t)~ADDRESSING_128K));
    ZX_ASSERT(*probe == 0x24);

    /* 128K substitution keeps the configured bank's upper bits. */
    ZX_ASSERT(bc_set_addressing(BC_ADDRESSING_128K) == ZX_OK);
    ZX_ASSERT(bc_readback_register(REG_ADDRESSING) == (eff7 | ADDRESSING_128K));
    ZX_ASSERT(*probe == 0xa9);
    ZX_ASSERT(bc_get_window_config(map, ZX_WINDOW_2, &config) == ZX_OK);
    ZX_ASSERT(config.physical_page == 8 && config.substitute_from_7ffd_or_dos == 1);
    ZX_ASSERT(bc_set_addressing((bc_addressing_t)2) == ZX_INVALID_ARGUMENT);

    /* In 128K mode bit 5 locks paging writes, including screen selection. */
    {
        uint8_t locked = (uint8_t)((original_paging & 0x18u) | 0x22u);
        zx_screen_t other = BC_PAGING_SCREEN(locked) == ZX_SCREEN_0 ? ZX_SCREEN_1 : ZX_SCREEN_0;
        z80_outp(PORT_PAGING, locked);
        ZX_ASSERT(bc_readback_register(REG_PAGING) == locked);
        ZX_ASSERT(bc_select_screen(other) == ZX_BUSY);
        ZX_ASSERT(bc_readback_register(REG_PAGING) == locked);
        ZX_ASSERT(*probe == 0xa9);
    }
    ZX_ASSERT(bc_set_addressing(BC_ADDRESSING_1024K) == ZX_OK);
    z80_outp(PORT_PAGING, (uint8_t)((original_paging & 0x18u) | 2u));
    ZX_ASSERT(*probe == 0x24);
    z80_outp(PORT_PAGING, original_paging);
    ZX_ASSERT(bc_set_addressing(original) == ZX_OK);
    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_2, 50) == ZX_OK);
    zx_test_step_marker("addressing");
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        check_readback();
        check_resync();
        check_addressing();
    }
    zx_test_finish();
    return 0;
}
