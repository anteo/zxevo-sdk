#include <tsconf/memory.h>
#include <tsconf/timing.h>
#include <zx_test.h>

int main(void) {
    zx_cpu_speed_t speed = ZX_CPU_14_MHZ;

    zx_test_init();
    ZX_ASSERT(zx_get_cpu_speed(0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_get_cpu_speed(&speed) == ZX_NOT_INITIALIZED && speed == ZX_CPU_14_MHZ);
    ZX_ASSERT(zx_set_cpu_speed(ZX_CPU_7_MHZ) == ZX_NOT_INITIALIZED);

    ZX_ASSERT(ts_set_cpu_speed_and_cache(ZX_CPU_7_MHZ, 2) == ZX_OK);
    ZX_ASSERT(zx_get_cpu_speed(&speed) == ZX_OK && speed == ZX_CPU_7_MHZ);
    zx_test_step_marker("7mhz-cache");

    ZX_ASSERT(zx_set_cpu_speed(ZX_CPU_14_MHZ) == ZX_OK);
    ZX_ASSERT(zx_get_cpu_speed(&speed) == ZX_OK && speed == ZX_CPU_14_MHZ);
    zx_test_step_marker("14mhz-cache");

    ZX_ASSERT(zx_set_cpu_speed((zx_cpu_speed_t)3) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_set_cpu_speed_and_cache((zx_cpu_speed_t)3, 0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_get_cpu_speed(&speed) == ZX_OK && speed == ZX_CPU_14_MHZ);
    zx_test_step_marker("invalid");

    ts_memory_set_cache(0x05);
    ZX_ASSERT(zx_set_cpu_speed(ZX_CPU_7_MHZ) == ZX_OK);
    ZX_ASSERT(zx_get_cpu_speed(&speed) == ZX_OK && speed == ZX_CPU_7_MHZ);
    zx_test_step_marker("7mhz-mixed-cache");

    ZX_ASSERT(ts_set_cpu_speed_and_cache(ZX_CPU_14_MHZ, 0) == ZX_OK);
    zx_test_step_marker("14mhz-uncached");

    ZX_ASSERT(zx_set_cpu_speed(ZX_CPU_3_5_MHZ) == ZX_OK);
    zx_test_step_marker("3.5mhz-uncached");

    zx_test_finish();
    return 0;
}
