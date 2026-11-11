#include <arch/z80.h>
#include <baseconf.h>
#include <string.h>

#include "bc_case.h"

enum { FONT_BYTES = 2048, PORT_BF = 0x00bf };

static uint8_t *const source = (uint8_t *)0x8000u;
static uint8_t *const destination = (uint8_t *)0x8800u;
static uint8_t *const backup = (uint8_t *)0x9000u;

static const uint8_t diamond[8] = {0x18, 0x3c, 0x7e, 0xff, 0xff, 0x7e, 0x3c, 0x18};
static const uint8_t checker[8] = {0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55};

static uint8_t ram_was_restored(void) {
    uint16_t i;
    for (i = 0; i < FONT_BYTES; ++i) {
        uint8_t pattern = (uint8_t)(i ^ (i >> 8) ^ 0xa7u);
        if (destination[i] != pattern || backup[i] != pattern) return 0;
    }
    return 1;
}

int main(void) {
    uint16_t i;
    uint8_t bf;
    if (bc_case_init() == ZX_OK) {
        ZX_ASSERT(bc_select_screen(ZX_SCREEN_0) == ZX_OK);
        ZX_ASSERT(bc_set_video_mode(BC_VIDEO_EVO_TEXT_80) == ZX_OK);
        ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_2, 48) == ZX_OK);
        ZX_ASSERT(zx_console_clear() == ZX_OK);
        ZX_ASSERT(zx_console_gotoxy(12, 8) == ZX_OK);
        ZX_ASSERT(zx_console_puts("ABAB") == ZX_OK);

        bf = z80_inp(PORT_BF);
        memset(source, 0, FONT_BYTES);
        memcpy(source + 'A' * 8, diamond, sizeof(diamond));
        memcpy(source + 'B' * 8, checker, sizeof(checker));
        ZX_ASSERT(bc_upload_font_to(source, destination + 1) == ZX_INVALID_ARGUMENT);
        ZX_ASSERT(bc_upload_font_to(source, source) == ZX_INVALID_ARGUMENT);
        ZX_ASSERT(bc_upload_font_to(source, destination) == ZX_OK);
        ZX_ASSERT(memcmp(source, destination, FONT_BYTES) == 0);
        ZX_ASSERT(z80_inp(PORT_BF) == bf);
        ZX_ASSERT(bc_read_font_row(0) == ZX_INVALID_ARGUMENT);
        zx_test_step_shot("upload");

        memcpy(source + 'A' * 8, checker, sizeof(checker));
        memcpy(source + 'B' * 8, diamond, sizeof(diamond));
        for (i = 0; i < FONT_BYTES; ++i) destination[i] = (uint8_t)(i ^ (i >> 8) ^ 0xa7u);
        ZX_ASSERT(bc_upload_font_preserving(source, destination, destination) ==
                  ZX_INVALID_ARGUMENT);
        ZX_ASSERT(bc_upload_font_preserving(source, destination, backup) == ZX_OK);
        ZX_ASSERT(ram_was_restored());
        ZX_ASSERT(z80_inp(PORT_BF) == bf);
        zx_test_step_shot("preserving");
    }
    zx_test_finish();
    return 0;
}
