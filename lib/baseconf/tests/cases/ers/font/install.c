#include <baseconf.h>
#include <string.h>

#include "bc_case.h"

/* mhmt -mlz on 2048 zeroed bytes with glyphs A=18 3C 7E FF FF 7E 3C 18
 * and B=AA 55 AA 55 AA 55 AA 55, at offsets 'A'*8 and 'B'*8. */
static const uint8_t packed_font[] = {
    0x00, 0x6e, 0xff, 0x60, 0x7e, 0x98, 0xff, 0x1f, 0xaf, 0xff, 0x18, 0x3c, 0x7e, 0xff, 0x1c,
    0x50, 0xc1, 0xda, 0xaa, 0x55, 0x18, 0xfe, 0x1d, 0x66, 0x03, 0x07, 0xe9, 0xff, 0x81, 0xfa,
    0xff, 0x60, 0x7e, 0x98, 0xff, 0x1f, 0xa6, 0xff, 0x07, 0xe9, 0xff, 0x80, 0x40,
};
/* ERS replaces W2 and W3 during unpacking. BSS in W1 remains readable. */
static uint8_t source[sizeof(packed_font)];

static void check_fonts(void) {
    zx_status_t status;

    status = bc_set_video_mode(BC_VIDEO_EVO_TEXT_80);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;
    ZX_ASSERT(bc_select_screen(ZX_SCREEN_0) == ZX_OK);
    zx_set_ink(15);
    zx_set_paper(0);
    ZX_ASSERT(zx_console_clear() == ZX_OK);
    ZX_ASSERT(zx_console_gotoxy(10, 8) == ZX_OK);
    ZX_ASSERT(zx_console_puts("AB  ABCDEFG  0123456789  \x80\x81\x82\x83  \xb0\xb1\xb2\xb3") ==
              ZX_OK);

    ZX_ASSERT(bc_ers_set_compressed_font(0, source) == ZX_OK);
    zx_test_step_shot("atm");
    ZX_ASSERT(bc_ers_set_compressed_font(1, source) == ZX_OK);
    zx_test_step_shot("cp866");

    memcpy(source, packed_font, sizeof(source));
    ZX_ASSERT(bc_ers_set_compressed_font(2, source) == ZX_OK);
    zx_test_step_shot("custom");
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        bc_ers_set_profile(BC_ERS_SERVICES_ROM);
        check_fonts();
    }
    zx_test_finish();
    return 0;
}
