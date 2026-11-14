#ifndef ZX_BLIT_H
#define ZX_BLIT_H

#include <stdint.h>
#include <zx/status.h>

/* Linear indexed 4bpp image: high nibble is the left pixel, rows run top to
 * bottom, stride is bytes between row starts and is >= ceil(width/2).
 * The caller owns enough readable memory for all rows. No bank switching or
 * decompression is implicit. A zero width/height is an empty image. */
typedef struct {
    const uint8_t *pixels;
    uint16_t width, height;
    uint16_t stride;
} zx_bitmap4_t;

/* Copy to the selected draw surface, clipping signed pixel coordinates to its
 * bounds. Supports BaseConf ATM320 and TSConf 16C (512x512 backing surface).
 * Does not change the displayed screen, palette, ink or paper. Odd edges
 * preserve the neighbouring pixel. The operation is synchronous and may nest
 * in zx_graphics_begin/end. Unsupported/excluded modes return ZX_UNSUPPORTED;
 * mapping/ownership failures propagate the video status without drawing.
 * Invalid descriptors, address wrap or stride return ZX_INVALID_ARGUMENT.
 * An empty image returns ZX_OK before acquiring the surface. With a valid
 * surface, a fully clipped rectangle returns ZX_OK without drawing.
 *
 * Source and destination must not overlap or physically alias. Keep code,
 * source and stack resident for the call and exclude concurrent drawing,
 * paging and surface changes by IRQ/NMI handlers. BaseConf needs both surface
 * pages already mapped writable and no active window lease. TSConf borrows
 * W3: code, stack and source must be outside W3; a source reaching into W3
 * returns ZX_UNSAFE_CONTEXT. The descriptor is copied before W3 is borrowed.
 * Supply banked resources as resident chunks between completed operations. */
zx_status_t zx_blit4(const zx_bitmap4_t *source, int16_t x, int16_t y);

/* As zx_blit4, but leave destination pixels unchanged where the source index
 * equals transparent_index (0..15). Other values return ZX_INVALID_ARGUMENT.
 * Opaque zx_blit4 copies index zero like every other color. */
zx_status_t zx_blit4_key(const zx_bitmap4_t *source, int16_t x, int16_t y,
                         uint8_t transparent_index);

#endif
