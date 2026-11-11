#include <baseconf.h>
#include <baseconf/ers.h>
#include <baseconf/rom.h>

#include "bc_case.h"

int main(void) {
    uint16_t quotient16 = 0;
    uint32_t product16 = 0;
    uint64_t product32x16 = 0;
    uint32_t dividend32 = 0x12345678UL;
    uint32_t divisor32 = 0x00000100UL;
    uint32_t quotient32 = 0;
    uint32_t remainder32 = 0;
    zx_status_t status;

    if (bc_case_init() != ZX_OK) {
        ZX_ASSERT(0);
        zx_test_finish();
        return 0;
    }

    /* The ERS runner keeps the real ROM in W0; code runs from W2 RAM. */
    bc_ers_set_profile(BC_ERS_SERVICES_ROM);

    status = bc_ers_math_multiply_u16(0xffffu, 0xffffu, &product16);
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK) ZX_ASSERT(product16 == 0xfffe0001UL);

    status = bc_ers_math_multiply_u32_u16(&dividend32, 16u, &product32x16);
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK) ZX_ASSERT(product32x16 == 0x0000000123456780ULL);
    zx_test_step_marker("multiply");

    status = bc_ers_math_divide_u16(0xffffu, 257u, &quotient16);
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK) ZX_ASSERT(quotient16 == 255u);

    status = bc_ers_math_divide_u32(&dividend32, &divisor32, &quotient32, &remainder32);
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK) {
        ZX_ASSERT(quotient32 == 0x00123456UL);
        ZX_ASSERT(remainder32 == 0x78UL);
    }
    zx_test_step_marker("divide");

    zx_test_finish();
    return 0;
}
