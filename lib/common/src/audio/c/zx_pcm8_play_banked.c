#include <zx/audio.h>
#include <zx/interrupt.h>
#include "../../audio/pcm8.h"

zx_status_t zx_pcm8_play_banked(const zx_pcm8_banked_t *sample, zx_window_t window,
                                zx_ram_lease_t *lease) {
    zx_status_t status;
    uint16_t first_address, last_address, offset, remaining;
    uint8_t page, irq;

    if (!sample || !lease || window > ZX_WINDOW_3) return ZX_INVALID_ARGUMENT;
    first_address = (uint16_t)sample;
    if (first_address > (uint16_t)(0xffffu - sizeof(*sample) + 1u)) return ZX_INVALID_ARGUMENT;
    last_address = first_address + sizeof(*sample) - 1u;
    if ((first_address >> 14) == window || (last_address >> 14) == window)
        return ZX_INVALID_ARGUMENT;
    first_address = (uint16_t)lease;
    if (first_address > (uint16_t)(0xffffu - sizeof(*lease) + 1u)) return ZX_INVALID_ARGUMENT;
    last_address = first_address + sizeof(*lease) - 1u;
    if ((first_address >> 14) == window || (last_address >> 14) == window)
        return ZX_INVALID_ARGUMENT;

    page = sample->first_page;
    offset = sample->offset;
    remaining = sample->length;
    if (offset >= ZX_RAM_PAGE_SIZE || !remaining || !sample->delay ||
        (uint16_t)page + ((remaining - 1u) >> 14) +
                ((offset + ((remaining - 1u) & 0x3fffu)) >> 14) >
            255u)
        return ZX_INVALID_ARGUMENT;

    irq = zx_interrupt_save_disable();
    status = zx_acquire_ram(window, page, lease);
    if (status != ZX_OK) {
        zx_interrupt_restore(irq);
        return status;
    }
    while (remaining) {
        uint16_t length = ZX_RAM_PAGE_SIZE - offset;
        if (length > remaining) length = remaining;
        zx__covox_pcm8_block((const uint8_t *)(((uint16_t)window << 14) + offset), length,
                             sample->delay);
        remaining -= length;
        offset = 0;
        if (remaining) {
            status = zx_acquired_ram_set_page(lease, ++page);
            if (status != ZX_OK) break;
        }
    }
    zx_covox_set_level(128);
    {
        zx_status_t release_status = zx_release_ram(lease);
        if (release_status != ZX_OK) status = release_status;
    }
    zx_interrupt_restore(irq);
    return status;
}
