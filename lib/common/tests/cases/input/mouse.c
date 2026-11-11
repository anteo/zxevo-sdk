#include <arch/z80.h>
#include <zx/input.h>
#include <zx_test.h>

int main(void) {
    const zx_mouse_snapshot_t previous = {253, 2, 15, ZX_MOUSE_RIGHT};
    const zx_mouse_snapshot_t current = {3, 254, 1, ZX_MOUSE_LEFT | ZX_MOUSE_MIDDLE};
    const zx_mouse_snapshot_t extremes = {131, 125, 9, 0};
    zx_mouse_snapshot_t sample;
    zx_mouse_delta_t delta;
    uint8_t flags;
    zx_test_init();
    ZX_ASSERT(zx_mouse_read(0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_mouse_read(&sample) == ZX_OK);
    flags = z80_inp(0xfadf);
    ZX_ASSERT(sample.x == z80_inp(0xfbdf) && sample.y == z80_inp(0xffdf));
    ZX_ASSERT(sample.wheel == (flags >> 4));
    ZX_ASSERT(sample.buttons == ((uint8_t)~flags & 7u));
    zx_test_step_marker("ports");

    delta = zx_mouse_delta(&previous, &current);
    ZX_ASSERT(delta.dx == 6 && delta.dy == -4 && delta.wheel == 2);
    ZX_ASSERT(delta.buttons == (ZX_MOUSE_LEFT | ZX_MOUSE_MIDDLE));
    delta = zx_mouse_delta(&current, &previous);
    ZX_ASSERT(delta.dx == -6 && delta.dy == 4 && delta.wheel == -2);
    ZX_ASSERT(delta.buttons == ZX_MOUSE_RIGHT);
    delta = zx_mouse_delta(&current, &extremes);
    ZX_ASSERT(delta.dx == -128 && delta.dy == 127 && delta.wheel == -8);
    ZX_ASSERT(delta.buttons == 0);
    zx_test_step_marker("wraparound");

    zx_test_finish();
    return 0;
}
