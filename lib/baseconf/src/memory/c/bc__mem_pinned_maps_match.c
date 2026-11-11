#include <baseconf.h>
#include "../internal.h"
#include "../../internal.h"

uint8_t bc__mem_pinned_maps_match(void) {
    uint8_t window;
    uint8_t config_bits;
    uint8_t substitute_bits;
    uint8_t protect_bits;
    if (!bc_mem_pinned_window_mask) return 1;
    config_bits = bc_readback_register(8);
    substitute_bits = bc_readback_register(9);
    protect_bits = bc_readback_register(0x12);
    for (window = 0; window < 4; ++window) {
        if (bc_mem_pinned_window_mask & (1u << window)) {
            bc__mem_decode_window(0, window, config_bits, substitute_bits, protect_bits,
                                  bc_readback_register(window));
            bc__mem_decode_window(1, window, config_bits, substitute_bits, protect_bits,
                                  bc_readback_register((uint8_t)(4u + window)));
            if (bc_mem_window_cache[0][window].kind != bc_mem_window_cache[1][window].kind ||
                bc_mem_window_cache[0][window].physical_page !=
                    bc_mem_window_cache[1][window].physical_page ||
                bc_mem_window_cache[0][window].substitute_from_7ffd_or_dos !=
                    bc_mem_window_cache[1][window].substitute_from_7ffd_or_dos ||
                bc_mem_window_cache[0][window].write_protected !=
                    bc_mem_window_cache[1][window].write_protected)
                return 0;
        }
    }
    return 1;
}
