#include <baseconf.h>
#include "../internal.h"
#include "../../internal.h"

void bc__mem_refresh_all_windows(void) {
    uint8_t map;
    uint8_t window;
    uint8_t config_bits = bc_readback_register(8);
    uint8_t substitute_bits = bc_readback_register(9);
    uint8_t protect_bits = bc_readback_register(0x12);

    bc_mem_active_map = bc_get_active_map();
    for (map = 0; map < 2; ++map) {
        for (window = 0; window < 4; ++window) {
            uint8_t shift = (uint8_t)(map * 4u + window);
            bc__mem_decode_window(map, window, config_bits, substitute_bits, protect_bits,
                                  bc_readback_register(shift));
        }
    }
}
