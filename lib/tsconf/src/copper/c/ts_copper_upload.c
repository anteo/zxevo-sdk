#include <tsconf/copper.h>
#include <tsconf/video.h>

zx_status_t ts_copper_upload(uint16_t fmaps_base, uint8_t first_word, const uint16_t *words,
                             uint16_t count) {
    if ((fmaps_base & 0x0fffu) || count > 256u - first_word || (count && !words))
        return ZX_INVALID_ARGUMENT;
    ts_fmaps_write_words((volatile void *)(uintptr_t)(fmaps_base + 0x600u + 2u * first_word), words,
                         count);
    return ZX_OK;
}
