#include <baseconf.h>
#include <baseconf/ers.h>
#include <baseconf/rom.h>
#include <string.h>

#include "bc_case.h"

static uint8_t sector_buffer[512];

static zx_status_t select_disk(void) {
    bc_ers_device_info_t device;
    zx_status_t status;

    status = bc_ers_device_find(&device);
    if (status != ZX_OK) return status;
    if (!device.found || device.partition_count != 1 || device.fat_type != 2) return ZX_UNAVAILABLE;
    return bc_ers_device_set_volume(0);
}

static void transfer_sector(bc_ers_transfer_direction_t direction, uint32_t sector) {
    bc_ers_nemo_transfer_result_t result;
    zx_status_t status =
        bc_ers_device_nemo_transfer(direction, 0, 1, sector, sector_buffer, &result);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;
    ZX_ASSERT(result.device_status == 0);
    ZX_ASSERT(result.next_buffer == sector_buffer + sizeof(sector_buffer));
    ZX_ASSERT(result.sector == sector);
}

int main(void) {
    bc_ers_nemo_transfer_result_t result;
    zx_status_t status;
    uint16_t index;

    if (bc_case_init() != ZX_OK) {
        ZX_ASSERT(0);
        zx_test_finish();
        return 0;
    }

    bc_ers_set_profile(BC_ERS_SERVICES_ROM);
    ZX_ASSERT(bc_ers_cmos_init() == ZX_OK);

    ZX_ASSERT(bc_ers_device_set_sector_number(0, 0, 0) == ZX_OK);
    zx_test_step_marker("sector_number");

    ZX_ASSERT(bc_ers_device_nemo_transfer((bc_ers_transfer_direction_t)2, 0, 1, 0, sector_buffer,
                                          &result) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(bc_ers_device_nemo_transfer(BC_ERS_TRANSFER_READ, 0, 1, 0, 0, &result) ==
              ZX_INVALID_ARGUMENT);
    ZX_ASSERT(bc_ers_device_nemo_transfer(BC_ERS_TRANSFER_READ, 0, 1, 0, sector_buffer, 0) ==
              ZX_INVALID_ARGUMENT);
    zx_test_step_marker("reject_invalid_transfer");

    status = select_disk();
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK) {
        memset(sector_buffer, 0xa5, sizeof(sector_buffer));
        transfer_sector(BC_ERS_TRANSFER_READ, 0);
        zx_test_step_data("read_mbr", sector_buffer, sizeof(sector_buffer));

        /* LBA 1 lies between the MBR and the fixture's FAT partition. */
        for (index = 0; index < sizeof(sector_buffer); ++index) {
            sector_buffer[index] = (uint8_t)(index ^ (index >> 8) ^ 0xa5u);
        }
        transfer_sector(BC_ERS_TRANSFER_WRITE, 1);
        memset(sector_buffer, 0, sizeof(sector_buffer));
        transfer_sector(BC_ERS_TRANSFER_READ, 1);
        for (index = 0; index < sizeof(sector_buffer); ++index) {
            ZX_ASSERT(sector_buffer[index] == (uint8_t)(index ^ (index >> 8) ^ 0xa5u));
        }
        zx_test_step_marker("write_readback");
    }

    zx_test_finish();
    return 0;
}
