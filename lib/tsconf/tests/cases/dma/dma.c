#include <tsconf.h>
#include <zx_test.h>

static uint8_t *const w3 = (uint8_t *)0xc000;
static ts_dma_transfer_t transfer = {{0x3f00, 0x30}, {0x0202, 0x50}, 255, 1, TS_DMA_COPY};

static void check_copy(void) {
    uint16_t i;
    volatile uint8_t *destination = w3 + 0x0202;

    ts_memory_set_page3(0x30);
    for (i = 0; i < 256; ++i) {
        w3[0x3f00 + i] = (uint8_t)(i ^ 0x55);
    }
    ts_memory_set_page3(0x31);
    for (i = 0; i < 768; ++i) {
        w3[i] = (uint8_t)(i ^ 0xaa);
    }
    ts_memory_set_page3(0x50);
    destination[-1] = 0x19;
    destination[1023] = 0;
    destination[1024] = 0x91;
    ZX_ASSERT(!ts_dma_busy());
    ts_dma_start(&transfer);
    ZX_ASSERT(ts_dma_busy() == 1);
    ZX_ASSERT(ts_dma_wait_polls(4096) == ZX_OK);
    ZX_ASSERT(!ts_dma_busy());
    for (i = 0; i < 1024; ++i) {
        ZX_ASSERT(destination[i] == (uint8_t)(i ^ (i < 256 ? 0x55 : 0xaa)));
    }
    ZX_ASSERT(destination[-1] == 0x19);
    ZX_ASSERT(destination[1024] == 0x91);
    zx_test_step_marker("copy-across-pages");
}

static void check_fill(void) {
    uint8_t row;
    uint16_t column;
    volatile uint8_t *destination = w3 + 0x1006;

    ts_memory_set_page3(0x60);
    w3[0x0102] = 0x34;
    w3[0x0103] = 0xc8;
    for (row = 0; row < 3; ++row) {
        for (column = 0; column < 9; ++column) {
            destination[512u * row + column] = 0;
        }
    }

    transfer.source.offset = 0x0102;
    transfer.source.page = 0x60;
    transfer.destination.offset = 0x1006;
    transfer.destination.page = 0x60;
    transfer.words_minus_one = 3;
    transfer.bursts_minus_one = 2;
    transfer.control = TS_DMA_FILL | TS_DMA_STRIDE_DESTINATION | TS_DMA_STRIDE_512;
    ts_dma_start(&transfer);
    ts_dma_wait();
    for (row = 0; row < 3; ++row) {
        for (column = 0; column < 8; ++column) {
            ZX_ASSERT(destination[512u * row + column] == (column & 1 ? 0xc8 : 0x34));
        }
        ZX_ASSERT(destination[512u * row + 8] == 0);
    }
    zx_test_step_marker("strided-word-fill");
}

static void check_strided_copy(void) {
    uint8_t row;
    uint16_t offset;
    volatile uint8_t *source = w3 + 0x32;
    volatile uint8_t *destination = w3 + 0x1004;

    ts_memory_set_page3(0x60);
    for (row = 0; row < 3; ++row) {
        offset = 256u * row;
        source[offset] = (uint8_t)(0x10u + row);
        source[offset + 1] = (uint8_t)(0x90u + row);
        destination[offset] = 0;
        destination[offset + 1] = 0;
        destination[offset + 2] = 0x5a;
    }

    transfer.source.offset = 0x32;
    transfer.source.page = 0x60;
    transfer.destination.offset = 0x1004;
    transfer.destination.page = 0x60;
    transfer.words_minus_one = 0;
    transfer.bursts_minus_one = 2;
    transfer.control = TS_DMA_COPY | TS_DMA_STRIDE_SOURCE | TS_DMA_STRIDE_DESTINATION;
    ts_dma_start(&transfer);
    ts_dma_wait();
    for (row = 0; row < 3; ++row) {
        offset = 256u * row;
        ZX_ASSERT(destination[offset] == 0x10u + row);
        ZX_ASSERT(destination[offset + 1] == 0x90u + row);
        ZX_ASSERT(destination[offset + 2] == 0x5a);
    }
    zx_test_step_marker("strided-copy");
}

static void check_blit(void) {
    volatile uint8_t *source = w3 + 0x2000;
    volatile uint8_t *destination = w3 + 0x2100;

    ts_memory_set_page3(0x60);
    transfer.source.offset = 0x2000;
    transfer.source.page = 0x60;
    transfer.destination.offset = 0x2100;
    transfer.destination.page = 0x60;
    transfer.words_minus_one = 0;
    transfer.bursts_minus_one = 0;
    source[0] = 0x04;
    source[1] = 0x70;
    destination[0] = 0xa1;
    destination[1] = 0x2b;
    transfer.control = TS_DMA_BLIT_TRANSPARENT;
    ts_dma_start(&transfer);
    ZX_ASSERT(ts_dma_wait_polls(4096) == ZX_OK);
    ZX_ASSERT(destination[0] == 0xa4 && destination[1] == 0x7b);
    zx_test_step_marker("transparent-blit");
}

static void check_optional_registers(void) {
    volatile uint8_t *destination = w3 + 0x2200;

    ZX_ASSERT(ts_dma_configure_wait_port(TS_DMA_WAIT_SERIAL, 0xd4) == ZX_OK);
    ZX_ASSERT(ts_dma_configure_wait_port(2, 0) == ZX_INVALID_ARGUMENT);
    zx_test_step_marker("wait-port");

    transfer.destination.offset = 0x2200;
    transfer.words_minus_one = 0;
    transfer.bursts_minus_one = 0;
    transfer.control = TS_DMA_COPY;
    ts_dma_start_extended(&transfer, 3);
    ZX_ASSERT(ts_dma_wait_polls(4096) == ZX_OK);
    ZX_ASSERT(destination[0] == 0x04 && destination[1] == 0x70);
    zx_test_step_marker("extended-burst");

    ts_dma_start(&transfer);
    ZX_ASSERT(ts_dma_wait_polls(4096) == ZX_OK);
    zx_test_step_marker("ordinary-burst");
}

int main(void) {
    zx_test_init();
    ts_memory_set_cache(0);
    ts_dma_wait();
    ZX_ASSERT(ts_dma_wait_polls(0) == ZX_TIMEOUT);
    ZX_ASSERT(ts_dma_wait_polls(1) == ZX_OK);
    check_copy();
    check_fill();
    check_strided_copy();
    check_blit();
    check_optional_registers();
    zx_test_finish();
    return 0;
}
