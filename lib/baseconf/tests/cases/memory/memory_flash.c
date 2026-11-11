#include <baseconf.h>

#include "bc_case.h"

int main(void) {
    volatile const uint8_t *const resident_rom = (volatile const uint8_t *)0x0100u;
    volatile uint8_t *const scratch = (volatile uint8_t *)0xc100u;
    bc_window_config_t resident;
    bc_window_config_t mapped;
    uint8_t i;
    uint8_t has_rom_data = 0;

    if (bc_case_init() == ZX_OK) {
        bc_map_t map = bc_get_active_map();
        uint8_t protect_bit = (uint8_t)(8u << (4 * map));
        zx_status_t status = bc_get_window_config(map, ZX_WINDOW_0, &resident);
        ZX_ASSERT(status == ZX_OK);
        if (status == ZX_OK) {
            ZX_ASSERT(resident.kind == BC_FLASH && resident.substitute_from_7ffd_or_dos == 0);
            ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_3, 52) == ZX_OK);
            *scratch = 0x6c;
            ZX_ASSERT(bc_map_flash_bank(ZX_WINDOW_3, resident.physical_page) == ZX_OK);
            ZX_ASSERT(bc_get_window_config(map, ZX_WINDOW_3, &mapped) == ZX_OK);
            ZX_ASSERT(mapped.kind == BC_FLASH && mapped.physical_page == resident.physical_page);
            ZX_ASSERT(mapped.substitute_from_7ffd_or_dos == 0 && mapped.write_protected == 1);
            ZX_ASSERT((bc_readback_register(0x12) & protect_bit) != 0);
            for (i = 0; i < 32; ++i) {
                uint8_t expected = resident_rom[i];
                ZX_ASSERT(scratch[i] == expected);
                if (expected != 0xff) has_rom_data = 1;
            }
            ZX_ASSERT(has_rom_data);
            ZX_ASSERT(bc_map_flash_bank(ZX_WINDOW_3, 32) == ZX_INVALID_ARGUMENT);
            ZX_ASSERT(*scratch == *resident_rom);
            ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_3, 52) == ZX_OK);
            ZX_ASSERT((bc_readback_register(0x12) & protect_bit) == 0);
            ZX_ASSERT(*scratch == 0x6c);
        }
        zx_test_step_marker("flash_window");
    }
    zx_test_finish();
    return 0;
}
