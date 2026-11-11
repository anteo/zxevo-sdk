#include <baseconf.h>

#include "bc_case.h"

static void check_cpu_speed(void) {
    zx_cpu_speed_t initial, current, speed;
    ZX_ASSERT(zx_get_cpu_speed(&initial) == ZX_OK);
    ZX_ASSERT(zx_get_cpu_speed(0) == ZX_INVALID_ARGUMENT);
    for (speed = ZX_CPU_3_5_MHZ; speed <= ZX_CPU_14_MHZ; ++speed) {
        ZX_ASSERT(zx_set_cpu_speed(speed) == ZX_OK);
        ZX_ASSERT(zx_get_cpu_speed(&current) == ZX_OK && current == speed);
    }
    ZX_ASSERT(zx_set_cpu_speed((zx_cpu_speed_t)3) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_get_cpu_speed(&current) == ZX_OK && current == ZX_CPU_14_MHZ);
    ZX_ASSERT(zx_set_cpu_speed(initial) == ZX_OK);
    zx_test_step_marker("cpu_speed");
}

static void check_frame_period(void) {
    static const uint32_t periods[] = {71680u, 58688u, 69888u, 70908u};
    bc_video_output_t output;
    uint32_t period = 0;
    ZX_ASSERT(zx_frame_period(0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_frame_period(&period) == ZX_UNSAFE_CONTEXT);
    ZX_ASSERT(period == 0);
    ZX_ASSERT(zx_avr_window_select(ZX_AVR_WINDOW_VERSION) == ZX_OK);
    ZX_ASSERT(bc_read_video_output(&output) == ZX_OK);
    ZX_ASSERT(zx_frame_period(&period) == ZX_OK);
    ZX_ASSERT(period == periods[output.raster]);
    zx_test_step_marker("frame_period");
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        check_cpu_speed();
        check_frame_period();
    }
    zx_test_finish();
    return 0;
}
