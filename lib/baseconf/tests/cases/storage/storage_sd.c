#include <arch/z80.h>
#include <baseconf.h>
#include <string.h>

#include "bc_case.h"

static zx_sd_transaction_t transaction;
static uint8_t sector[512];

static void emulator_card_select(uint8_t selected) {
    bc_paging_snapshot_t snapshot;
    uint8_t shadow;
    if (!transaction.control_port_high) return;
    shadow = BC_CONFIG_SHADOW_PORTS(z80_inp(0x00bf));
    /* ZEsarUX treats shadow 8057h writes as SPI data. Select the
     * test card through the ordinary 77h port, then restore decoding. */
    ZX_ASSERT(bc_get_paging_state(&snapshot) == ZX_OK);
    ZX_ASSERT(bc_set_shadow_ports_override(1) == ZX_OK);
    z80_outp(snapshot.saved_xx77_address | 0x0200u, snapshot.saved_xx77_data);
    ZX_ASSERT(bc_set_shadow_ports_override(0) == ZX_OK);
    z80_outp(0x0077, selected ? 1 : 3);
    ZX_ASSERT(bc_set_shadow_ports_override(1) == ZX_OK);
    z80_outp(snapshot.saved_xx77_address, snapshot.saved_xx77_data);
    ZX_ASSERT(bc_set_shadow_ports_override(shadow) == ZX_OK);
}

static uint8_t receive(void) {
    uint8_t value = 0xff;
    ZX_ASSERT(zx_sd_receive_previous(&transaction, &value) == ZX_OK);
    return value;
}

static uint8_t read_sector(uint16_t offset) {
    uint8_t response;
    zx_status_t status = zx_sd_command(&transaction, 17, offset, &response);
    ZX_ASSERT(status == ZX_OK && response == 0);
    if (status != ZX_OK || response != 0) return 0;
    status = zx_sd_wait_data(&transaction, 16);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return 0;
    ZX_ASSERT(zx_sd_read_block(&transaction, sector) == ZX_OK);
    (void)receive();
    (void)receive();
    return 1;
}

static void check_card(void) {
    zx_sd_transaction_t other = {0};
    uint8_t shadow = BC_CONFIG_SHADOW_PORTS(z80_inp(0x00bf));
    uint8_t response;
    uint16_t i;
    zx_status_t status = zx_sd_begin(&transaction);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;
    ZX_ASSERT(zx_sd_begin(&other) == ZX_BUSY);
    ZX_ASSERT(zx_sd_receive_previous(&transaction, &response) == ZX_BUSY);
    ZX_ASSERT(zx_sd_end(&other) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_sd_wait_data(&transaction, 0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_sd_command(&other, 0, 0, &response) == ZX_INVALID_ARGUMENT);
    emulator_card_select(1);
    ZX_ASSERT(zx_sd_command(&transaction, 0, 0, &response) == ZX_OK && response == 1);
    zx_test_step_marker("transaction");

    if (read_sector(0)) {
        ZX_ASSERT(sector[450] == 6 && sector[455] == 8);
        ZX_ASSERT(sector[510] == 0x55 && sector[511] == 0xaa);
    }
    zx_test_step_marker("read_mbr");

    for (i = 0; i < sizeof(sector); ++i) sector[i] = (uint8_t)(i ^ (i >> 8) ^ 0x6du);
    status = zx_sd_command(&transaction, 24, 512, &response);
    ZX_ASSERT(status == ZX_OK && response == 0);
    if (status == ZX_OK && response == 0) {
        ZX_ASSERT(zx_sd_transmit(&transaction, 0xfe) == ZX_OK);
        ZX_ASSERT(zx_sd_write_block(&transaction, sector) == ZX_OK);
        ZX_ASSERT(zx_sd_transmit(&transaction, 0xff) == ZX_OK);
        ZX_ASSERT(zx_sd_transmit(&transaction, 0xff) == ZX_OK);
    }
    ZX_ASSERT(zx_sd_end(&transaction) == ZX_OK);
    ZX_ASSERT(BC_CONFIG_SHADOW_PORTS(z80_inp(0x00bf)) == shadow);
    ZX_ASSERT(zx_sd_end(&transaction) == ZX_INVALID_ARGUMENT);
    emulator_card_select(0);

    status = zx_sd_begin(&transaction);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;
    emulator_card_select(1);
    memset(sector, 0, sizeof(sector));
    if (read_sector(512)) {
        for (i = 0; i < sizeof(sector); ++i)
            ZX_ASSERT(sector[i] == (uint8_t)(i ^ (i >> 8) ^ 0x6du));
    }
    ZX_ASSERT(zx_sd_end(&transaction) == ZX_OK);
    ZX_ASSERT(BC_CONFIG_SHADOW_PORTS(z80_inp(0x00bf)) == shadow);
    emulator_card_select(0);
    zx_test_step_marker("block_roundtrip");
}

int main(void) {
    if (bc_case_init() == ZX_OK) check_card();
    zx_test_finish();
    return 0;
}
