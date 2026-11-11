#include "../internal.h"

zx_status_t zx_rtc_read(zx_rtc_index_t index, uint8_t *value) {
    uint8_t irq, byte;

    if (!value || index > TS_RTC_MODIFIERS_EXT) return ZX_INVALID_ARGUMENT;
    irq = zx_interrupt_save_disable();
    byte = zx__rtc_read_scoped((uint8_t)index);
    zx_interrupt_restore(irq);
    *value = byte;
    return ZX_OK;
}

zx_status_t zx_rtc_write(zx_rtc_index_t index, uint8_t value) {
    uint8_t irq;

    if (index > ZX_RTC_CONTROL_C) return ZX_INVALID_ARGUMENT;
    irq = zx_interrupt_save_disable();
    zx__rtc_write_scoped((uint8_t)index, value);
    zx_interrupt_restore(irq);
    return ZX_OK;
}
