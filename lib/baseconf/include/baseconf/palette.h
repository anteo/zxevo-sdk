#ifndef BASECONF_PALETTE_H
#define BASECONF_PALETTE_H

#include <stdint.h>
#include <baseconf.h>

#define BC_PACK_PENTAGON_PIXELS(left_, right_)                                                     \
    ((uint8_t)((((left_) & 8u) << 3) | (((right_) & 8u) << 4) | (((right_) & 7u) << 3) |           \
               (((left_) & 7u))))

typedef uint8_t bc_color_index_t;
typedef uint8_t bc_ulaplus_index_t;

typedef struct {
    uint8_t r, g, b;
} bc_rgb222_t;

typedef struct {
    uint8_t r, g, b;
} bc_rgb444_t;

typedef struct {
    uint8_t ink, paper, paper_bright;
} bc_atm_attribute_t;

/* Return 1 when the live ATM palette uses RGB444, otherwise 0. */
uint8_t bc_get_atm_rgb444_enabled(void);
/* Select RGB444 for nonzero enabled or RGB222 for zero. Preserves the other
 * BF bits and the xx77 system configuration. The caller must exclude NMI. */
void bc_set_atm_rgb444_enabled(uint8_t enabled) __z88dk_fastcall;
/* Return the value last set through this API; no hardware readback, ZX_UNAVAILABLE if uncached. */
zx_status_t bc_get_atm_palette_rgb444(bc_color_index_t index, bc_rgb444_t *color);
/* Set the ATM entry selected by the current raster beam color; channels are
 * 0..3. index (0..15) only declares the expected beam color: it is validated but
 * not used to address hardware or checked against the beam. The caller must
 * time the write. Returns ZX_UNAVAILABLE in RGB444 hardware mode and
 * ZX_INVALID_ARGUMENT for out-of-range index/channels. */
zx_status_t bc_set_atm_palette(bc_color_index_t index, bc_rgb222_t color);
/* Set the current-beam ATM RGB444 color; index and channels are 0..15.
 * As with bc_set_atm_palette, the caller must time the write for the intended
 * entry; index labels the software cache and does not address hardware.
 * Returns ZX_UNAVAILABLE unless RGB444 hardware mode is already enabled and
 * ZX_INVALID_ARGUMENT for out-of-range index/channels. */
zx_status_t bc_set_atm_palette_rgb444(bc_color_index_t index, bc_rgb444_t color);
/* Write the ULAplus mode register; pass exactly 0 to disable or 1 to enable.
 * The byte is written unchanged, without validation or video-mode selection. */
void bc_set_ulaplus_enabled(uint8_t enabled);
/* Set ULAplus entry 0..63 to packed GGRRRBBB without enabling ULAplus.
 * Returns ZX_INVALID_ARGUMENT outside that range and ZX_UNAVAILABLE unless the
 * live hardware mode is ZX_256 or ZX_MULTICOLOR. */
zx_status_t bc_set_ulaplus_palette(bc_ulaplus_index_t index, uint8_t ggrrrbbb);
/* Decode the left 4-bit pixel from the shared Pentagon pair byte. */
uint8_t bc_unpack_pentagon_left(uint8_t packed);
/* Decode the right 4-bit pixel from the shared Pentagon pair byte. */
uint8_t bc_unpack_pentagon_right(uint8_t packed);

#endif
