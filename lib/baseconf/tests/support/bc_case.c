#include "bc_case.h"

#ifndef BC_TEST_PINNED
#define BC_TEST_PINNED 0x03u
#endif

zx_status_t bc_case_init(void) {
    zx_test_init();
    bc_ers_set_profile(BC_ERS_NONE);
    bc_set_pinned_windows((uint8_t)BC_TEST_PINNED);
    zx_set_colors(COLOR_BLACK, COLOR_WHITE, COLOR_BLACK);
    return ZX_OK;
}
