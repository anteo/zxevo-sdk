#include <baseconf/rtc.h>
#include <zx/timing.h>

zx_status_t zx_frame_period(uint32_t *tstates) __z88dk_fastcall {
    bc_video_output_t output;
    uint32_t period;
    zx_status_t status;
    if (!tstates) return ZX_INVALID_ARGUMENT;
    status = bc_read_video_output(&output);
    if (status != ZX_OK) return status;
    switch (output.raster) {
    case BC_RASTER_PENTAGON:
        period = 71680u;
        break;
    case BC_RASTER_60HZ:
        period = 58688u;
        break;
    case BC_RASTER_48K:
        period = 69888u;
        break;
    case BC_RASTER_128K:
        period = 70908u;
        break;
    default:
        return ZX_UNAVAILABLE;
    }
    *tstates = period;
    return ZX_OK;
}
