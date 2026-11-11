#include <baseconf/palette.h>

#include "bc_case.h"

int main(void) {
    uint16_t packed;

    if (bc_case_init() != ZX_OK) {
        ZX_ASSERT(0);
        zx_test_finish();
        return 0;
    }

    for (packed = 0; packed < 256u; ++packed) {
        const uint8_t value = (uint8_t)packed;
        const uint8_t left = bc_unpack_pentagon_left(value);
        const uint8_t right = bc_unpack_pentagon_right(value);

        ZX_ASSERT(left <= 15u);
        ZX_ASSERT(right <= 15u);
        ZX_ASSERT(BC_PACK_PENTAGON_PIXELS(left, right) == value);
    }

    zx_test_finish();
    return 0;
}
