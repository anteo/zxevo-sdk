#include <baseconf.h>
#include <baseconf/ers.h>
#include <baseconf/rom.h>
#include <string.h>

#include "bc_case.h"

static uint8_t decimal_equals(const char actual[11], const char *expected) {
    while (*expected) {
        if (*actual++ != *expected++) return 0;
    }
    return *actual == '\0';
}

static void check_u32(uint32_t value, const char *expected, char *failure) {
    char output[11];
    zx_status_t status;

    memset(output, '?', sizeof(output));
    status = bc_ers_math_u32_to_decimal(&value, output);
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK && !decimal_equals(output, expected)) {
        strcpy(failure, "expected \"");
        strcat(failure, expected);
        strcat(failure, "\", got \"");
        strncat(failure, output, sizeof(output));
        strcat(failure, "\"");
        zx_test_fail(__LINE__, failure);
    }
}

int main(void) {
    char u32_failure[sizeof("expected \"4294967295\", got \"           \"")];
    char output[11];
    zx_status_t status;

    if (bc_case_init() != ZX_OK) {
        ZX_ASSERT(0);
        zx_test_finish();
        return 0;
    }

    /* The ERS runner keeps the real ROM in W0; code runs from W2 RAM. */
    bc_ers_set_profile(BC_ERS_SERVICES_ROM);

    status = bc_ers_math_u8_to_decimal(255u, output);
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK) ZX_ASSERT(decimal_equals(output, "255"));

    status = bc_ers_math_u16_to_decimal(65535u, output);
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK) ZX_ASSERT(decimal_equals(output, "65535"));
    zx_test_step_marker("u8_u16");

    /* First value that hit the ROM's old 0xc4 cutoff after subtracting 10^9. */
    check_u32(0xff9aca00UL, "4288334336", u32_failure);
    zx_test_step_marker("u32_boundary");

    check_u32(0xffffffffUL, "4294967295", u32_failure);
    zx_test_step_marker("u32");

    zx_test_finish();
    return 0;
}
