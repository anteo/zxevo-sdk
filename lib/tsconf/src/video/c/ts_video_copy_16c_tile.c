#include <tsconf/dma.h>
#include <tsconf/video.h>

zx_status_t ts_video_copy_16c_tile(uint8_t source_page, uint8_t destination_page, uint8_t x,
                                   uint8_t y) {
    ts_dma_transfer_t transfer;
    if ((source_page & 7) || (destination_page & 7) || x >= 40 || y >= 25)
        return ZX_INVALID_ARGUMENT;
    if (source_page == destination_page) return ZX_OK;
    transfer.source.page = source_page + (y >> 3);
    transfer.destination.page = destination_page + (y >> 3);
    transfer.source.offset = transfer.destination.offset =
        ((uint16_t)(y & 7) << 11) + ((uint16_t)x << 2);
    transfer.words_minus_one = 1;
    transfer.bursts_minus_one = 7;
    transfer.control = TS_DMA_COPY | TS_DMA_STRIDE_SOURCE | TS_DMA_STRIDE_DESTINATION;
    ts_dma_wait();
    ts_dma_start(&transfer);
    ts_dma_wait();
    return ZX_OK;
}
