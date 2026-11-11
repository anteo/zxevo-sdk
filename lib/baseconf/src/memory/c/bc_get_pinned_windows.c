#include <baseconf.h>
#include "../internal.h"

uint8_t bc_get_pinned_windows(void) {
    return bc_mem_pinned_window_mask;
}
