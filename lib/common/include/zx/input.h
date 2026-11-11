#ifndef ZX_INPUT_H
#define ZX_INPUT_H

#include <stdint.h>
#include <zx/status.h>

typedef enum { ZX_MOUSE_LEFT = 1, ZX_MOUSE_RIGHT = 2, ZX_MOUSE_MIDDLE = 4 } zx_mouse_button_t;

typedef struct {
    uint8_t x, y, wheel, buttons;
} zx_mouse_snapshot_t;

typedef struct {
    int8_t dx, dy, wheel;
    uint8_t buttons;
} zx_mouse_delta_t;

/* Read Kempston mouse counters x/y (modulo 256), wheel (modulo 16), and pressed
 * button bits (zx_mouse_button_t). Counters are raw device values, not screen
 * coordinates. Returns ZX_INVALID_ARGUMENT for NULL snapshot, otherwise ZX_OK. */
zx_status_t zx_mouse_read(zx_mouse_snapshot_t *snapshot);
/* Subtract snapshots with wraparound: dx/dy are -128..127, wheel is -8..7;
 * buttons is copied from current. Both pointers must be non-NULL. Poll often
 * enough to avoid motion exceeding these signed ranges between snapshots. */
zx_mouse_delta_t zx_mouse_delta(const zx_mouse_snapshot_t *previous,
                                const zx_mouse_snapshot_t *current);

#endif
