#include <tsconf/dma.h>
#include <tsconf/video.h>

zx_status_t ts_video_copy_16c_screen(uint8_t source_page, uint8_t destination_page) {
    ts_dma_transfer_t transfer;
    uint8_t i;
    if ((source_page & 7) || (destination_page & 7)) return ZX_INVALID_ARGUMENT;
    if (source_page == destination_page) return ZX_OK;
    transfer.source.offset = 0;
    transfer.destination.offset = 0;
    transfer.words_minus_one = 255;
    transfer.bursts_minus_one = 31;
    transfer.control = TS_DMA_COPY;
    ts_dma_wait();
    for (i = 0; i < 4; ++i) {
        transfer.source.page = source_page + i;
        transfer.destination.page = destination_page + i;
        if (i == 3) transfer.bursts_minus_one = 3;
        ts_dma_start(&transfer);
        ts_dma_wait();
    }
    return ZX_OK;
}
