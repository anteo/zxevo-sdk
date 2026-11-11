#include "../internal.h"

zx_status_t zx__eeprom_transfer_byte(uint16_t offset, uint8_t *byte, uint8_t writing) {
    uint8_t irq = zx_interrupt_save_disable();
    uint8_t control = zx__rtc_read_scoped(ZX_RTC_CONTROL_C);
    uint8_t bank;
    uint8_t index = (uint8_t)(ZX__RTC_EXTENSION | (offset & 0x0fu));

    if (control == 0xffu) {
        zx_interrupt_restore(irq);
        return ZX_UNAVAILABLE;
    }
    control &= ZX__RTC_CONTROL_C_WRITABLE;
    bank = zx__rtc_read_scoped(ZX_RTC_CONTROL_A);
    zx__rtc_write_scoped(ZX_RTC_CONTROL_A, (uint8_t)(offset >> 4));
    if (!(control & ZX__RTC_EEPROM))
        zx__rtc_write_scoped(ZX_RTC_CONTROL_C, (uint8_t)(control | ZX__RTC_EEPROM));
    if (writing)
        zx__rtc_write_scoped(index, *byte);
    else
        *byte = zx__rtc_read_scoped(index);
    zx__rtc_write_scoped(ZX_RTC_CONTROL_A, bank);
    if (!(control & ZX__RTC_EEPROM)) zx__rtc_write_scoped(ZX_RTC_CONTROL_C, control);
    zx_interrupt_restore(irq);
    return ZX_OK;
}
