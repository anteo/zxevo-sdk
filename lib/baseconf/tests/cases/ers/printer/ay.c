#include <baseconf.h>
#include <arch/z80.h>

#include "bc_case.h"

#define CMOS_PRINTER_INDEX 0xedu
#define CMOS_PRINTER_ENABLE 0x20u
#define AY_MIXER 7u
#define AY_PORT_A 14u
#define AY_PORT_B 15u
#define AY_SELECT_PORT 0xfffdu
#define AY_WRITE_PORT 0xbffdu
#define BASIC_FLAGS_PRINTER 0x02u

void printer_test_copy_screen(void);

static uint8_t read_ay(uint8_t reg) {
    z80_outp(AY_SELECT_PORT, reg);
    return z80_inp(AY_SELECT_PORT);
}

static void seed_printer_data(void) {
    z80_outp(AY_SELECT_PORT, AY_PORT_A);
    z80_outp(AY_WRITE_PORT, 0x55);
}

static void check_screen_copy(void) {
    volatile uint8_t *const flags = (volatile uint8_t *)0x5c3bu;
    volatile uint8_t *const printer_buffer = (volatile uint8_t *)0x5b00u;
    uint8_t original_flags = *flags;

    *flags = original_flags | BASIC_FLAGS_PRINTER;
    printer_buffer[0] = 0x55;
    printer_buffer[255] = 0x55;
    seed_printer_data();
    ZX_ASSERT(bc_ers_printer_write_screen() == ZX_OK);
    ZX_ASSERT(read_ay(AY_PORT_A) == 0x07);
    ZX_ASSERT(read_ay(AY_MIXER) == 0x7f);
    ZX_ASSERT(printer_buffer[0] == 0x55 && printer_buffer[255] == 0x55);
    zx_test_step_marker("copy_screen_api");

    seed_printer_data();
    printer_test_copy_screen();
    ZX_ASSERT(read_ay(AY_PORT_A) == 0x07);
    ZX_ASSERT(read_ay(AY_MIXER) == 0x7f);
    ZX_ASSERT(printer_buffer[0] == 0 && printer_buffer[255] == 0);
    *flags = original_flags;
}

int main(void) {
    uint8_t original;
    zx_status_t status;

    if (bc_case_init() != ZX_OK) goto finish;
    bc_ers_set_profile(BC_ERS_SERVICES_ROM);
    ZX_ASSERT(bc_ers_cmos_init() == ZX_OK);
    status = bc_ers_cmos_read(CMOS_PRINTER_INDEX, &original);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) goto finish;
    ZX_ASSERT(bc_ers_cmos_write(CMOS_PRINTER_INDEX, original | CMOS_PRINTER_ENABLE) == ZX_OK);

    seed_printer_data();
    ZX_ASSERT(bc_ers_printer_init() == ZX_OK);
    ZX_ASSERT(read_ay(AY_MIXER) == 0x7f);
    ZX_ASSERT(read_ay(AY_PORT_B) == 0xfe);
    ZX_ASSERT(read_ay(AY_PORT_A) == 0x07);
    zx_test_step_marker("initialize");

    ZX_ASSERT(bc_ers_printer_write('Z') == ZX_OK);
    ZX_ASSERT(read_ay(AY_PORT_A) == 'Z');
    ZX_ASSERT(read_ay(AY_MIXER) == 0x7f);
    zx_test_step_marker("write_character");

    ZX_ASSERT(bc_ers_printer_put_token(0x01) == ZX_OK);
    ZX_ASSERT(read_ay(AY_PORT_A) == 'Z');
    ZX_ASSERT(bc_ers_printer_put_token(0x90) == ZX_OK);
    ZX_ASSERT(read_ay(AY_PORT_A) == 'A');
    ZX_ASSERT(bc_ers_printer_put_token('\r') == ZX_OK);
    ZX_ASSERT(read_ay(AY_PORT_A) == '\n');
    zx_test_step_marker("print_tokens");

    check_screen_copy();
    zx_test_step_marker("copy_screen");

    ZX_ASSERT(bc_ers_cmos_write(CMOS_PRINTER_INDEX, original & ~CMOS_PRINTER_ENABLE) == ZX_OK);
    seed_printer_data();
    ZX_ASSERT(bc_ers_printer_write_screen() == ZX_OK);
    ZX_ASSERT(read_ay(AY_PORT_A) == 0x55);
    ZX_ASSERT(bc_ers_cmos_write(CMOS_PRINTER_INDEX, original) == ZX_OK);
    zx_test_step_marker("copy_screen_disabled");

finish:
    zx_test_finish();
    return 0;
}
