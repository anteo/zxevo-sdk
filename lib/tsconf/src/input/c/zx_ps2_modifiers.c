#include <zx/ps2.h>
#include "../../rtc/internal.h"

zx_status_t zx_ps2_modifiers(uint16_t *modifiers) {
    uint8_t irq, low, high;

    if (!modifiers) return ZX_INVALID_ARGUMENT;
    irq = zx_interrupt_save_disable();
    low = zx__rtc_read_scoped(ZX_RTC_MODIFIERS);
    if (low & 0x80u) {
        /* The single-mask AVR protocol marks 0Dh with D7 and uses 0Eh
         * as NVRAM. If all bits are set, distinguish it from an open bus. */
        high = 0;
        if (low == 0xffu && zx__rtc_read_scoped(ZX_RTC_CONTROL_B) == 0xffu) high = 0xffu;
        low &= 0x7fu;
    } else {
        high = zx__rtc_read_scoped(TS_RTC_MODIFIERS_EXT);
    }
    zx_interrupt_restore(irq);
    if (high & 0xf8u) return ZX_UNAVAILABLE;
    *modifiers = (uint16_t)low | ((uint16_t)high << 8);
    return ZX_OK;
}
