#include "../internal.h"

zx_status_t zx_nvram_read(uint8_t index, uint8_t *value) {
    uint8_t irq, byte;

    if (!value || index < 0x0fu || index >= 0xf0u) return ZX_INVALID_ARGUMENT;
    irq = zx_interrupt_save_disable();
    byte = zx__rtc_read_scoped(index);
    zx_interrupt_restore(irq);
    *value = byte;
    return ZX_OK;
}

zx_status_t zx_nvram_write(uint8_t index, uint8_t value) {
    uint8_t irq;

    if (index < 0x0fu || index >= 0xf0u) return ZX_INVALID_ARGUMENT;
    irq = zx_interrupt_save_disable();
    zx__rtc_write_scoped(index, value);
    zx_interrupt_restore(irq);
    return ZX_OK;
}
