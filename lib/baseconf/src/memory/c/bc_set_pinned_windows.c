#include <baseconf.h>
#include "../internal.h"
#include "../../video/internal.h"

void bc_set_pinned_windows(uint8_t mask) {
    bc_video_bound_slots = 0;  /* Recheck each slot against the new pins on selection. */
    bc_mem_pinned_window_mask = mask;
    bc_mem_pinned_window_override = 1;
}
