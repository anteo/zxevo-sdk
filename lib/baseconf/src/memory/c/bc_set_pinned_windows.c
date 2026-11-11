#include <baseconf.h>
#include "../internal.h"

void bc_set_pinned_windows(uint8_t mask) {
    bc_mem_pinned_window_mask = mask;
    bc_mem_pinned_window_override = 1;
}
