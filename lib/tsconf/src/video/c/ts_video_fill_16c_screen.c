#include <tsconf/dma.h>
#include <tsconf/memory.h>
#include <tsconf/video.h>

zx_status_t ts_video_fill_16c_screen(uint8_t page, uint8_t color) {
    ts_window_lease_t lease;
    ts_dma_transfer_t transfer;
    uint8_t i;
    zx_status_t status;
    if ((page & 7) || color > 15) return ZX_INVALID_ARGUMENT;
    status = ts_window_acquire(ZX_WINDOW_3, page, &lease);
    if (status != ZX_OK) return status;
    *(volatile uint16_t *)0xc000u = (uint16_t)color * 0x1111u;
    ts_window_release(&lease);
    transfer.source.page = page;
    transfer.source.offset = 0;
    transfer.destination.offset = 0;
    transfer.words_minus_one = 255;
    transfer.bursts_minus_one = 31;
    transfer.control = TS_DMA_FILL;
    ts_dma_wait();
    for (i = 0; i < 4; ++i) {
        transfer.destination.page = page + i;
        if (i == 3) transfer.bursts_minus_one = 3;
        ts_dma_start(&transfer);
        ts_dma_wait();
    }
    return ZX_OK;
}
