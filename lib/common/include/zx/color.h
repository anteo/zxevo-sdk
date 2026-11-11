#ifndef ZX_COLOR_H
#define ZX_COLOR_H

#include <stdint.h>

/* Standard unshifted ZX color indices for ink, paper and border.
 * COLOR_BRIGHT is the palette index bit. ZX_ATTR takes brightness
 * separately. */
enum {
    COLOR_BLACK = 0,
    COLOR_BLUE = 1,
    COLOR_RED = 2,
    COLOR_MAGENTA = 3,
    COLOR_GREEN = 4,
    COLOR_CYAN = 5,
    COLOR_YELLOW = 6,
    COLOR_WHITE = 7,
    COLOR_BRIGHT = 8
};

/* Pack the standard ZX Spectrum attribute byte. */
#define ZX_ATTR(ink_, paper_, bright_, flash_)                                                     \
    ((uint8_t)(((ink_) & 7u) | (((paper_) & 7u) << 3) | (((bright_) & 1u) << 6) |                  \
               (((flash_) & 1u) << 7)))

typedef struct {
    uint8_t ink, paper, bright, flash;
} zx_attribute_t;

/* Shared colors for the console and packed drawing primitives.
 * Initially ink is 0 and paper is 7.
 * Setters store the full byte without writing the hardware palette.
 * Use 0..15 for BaseConf and 0..255 for TSConf 256c. ZX, 16c and hardware
 * text interpret the low four bits in the selected surface's format. */
void zx_set_ink(uint8_t index);
void zx_set_paper(uint8_t index);

/* Set border color 0..15 without changing paging, audio or palette contents.
 * BaseConf uses its ATM palette. TSConf uses CRAM entries F0h..FFh, the
 * default ZX palette bank, regardless of the current graphics palette bank. */
void zx_set_border_color(uint8_t index) __z88dk_fastcall;

/* Set the border and store the foreground/background indices in one call.
 * The indices follow the same rules as the individual setters. */
void zx_set_colors(uint8_t border, uint8_t ink, uint8_t paper);

#endif
