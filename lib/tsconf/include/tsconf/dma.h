#ifndef TSCONF_DMA_H
#define TSCONF_DMA_H

#include <stdint.h>
#include <zx/status.h>

#define TS_DMA_COPY 0x01u
#define TS_DMA_SPI_TO_RAM 0x02u
#define TS_DMA_IDE_TO_RAM 0x03u
#define TS_DMA_FILL 0x04u
#define TS_DMA_FDR_TO_RAM 0x05u
#define TS_DMA_BLIT_ADD 0x06u
#define TS_DMA_WAIT_TO_RAM 0x07u
#define TS_DMA_BLIT_TRANSPARENT 0x81u
#define TS_DMA_RAM_TO_SPI 0x82u
#define TS_DMA_RAM_TO_IDE 0x83u
#define TS_DMA_RAM_TO_CRAM 0x84u
#define TS_DMA_RAM_TO_SFILE 0x85u
#define TS_DMA_RAM_TO_COPPER 0x86u
#define TS_DMA_STRIDE_512 0x08u
#define TS_DMA_BLIT_BYTES 0x08u
#define TS_DMA_STRIDE_DESTINATION 0x10u
#define TS_DMA_STRIDE_SOURCE 0x20u
#define TS_DMA_BLIT_SATURATE 0x40u

#define TS_DMA_WAIT_RTC 0u
#define TS_DMA_WAIT_SERIAL 1u

typedef struct {
    uint16_t offset; /* even byte offset within the 16 KiB page */
    uint8_t page;
} ts_dma_address_t;

typedef struct {
    ts_dma_address_t source;
    ts_dma_address_t destination;
    uint8_t words_minus_one;  /* 1..256 words per burst */
    uint8_t bursts_minus_one; /* 1..256 bursts */
    uint8_t control;
} ts_dma_transfer_t;

/* Program and start a DMA transfer. The caller owns an idle engine, supplies
 * supported control bits and keeps CPU mappings of the DMA buffers uncached.
 * RAM copies run forward. For a fill, source points to the repeated word.
 * On a strided side keep each burst within its stride. The descriptor can be
 * reused when this call returns. The buffers remain in use until DMA is idle. */
void ts_dma_start(const ts_dma_transfer_t *transfer) __z88dk_fastcall;

/* Start on an FDR build using bits 9:8 of bursts_minus_one in burst_high.
 * The caller supplies 0..3. ts_dma_start clears those two bits. */
void ts_dma_start_extended(const ts_dma_transfer_t *transfer, uint8_t burst_high);

/* Select the AVR WAIT service and service index for TS_DMA_WAIT_TO_RAM.
 * Requires an idle engine and exclusive access to the WAIT address latch.
 * Returns ZX_INVALID_ARGUMENT unless device is TS_DMA_WAIT_RTC or
 * TS_DMA_WAIT_SERIAL, otherwise ZX_OK. */
zx_status_t ts_dma_configure_wait_port(uint8_t device, uint8_t address);

/* Return 1 if busy, 0 if idle. */
uint8_t ts_dma_busy(void);

/* Poll until idle, with no timeout. The active transfer must be able to finish. */
void ts_dma_wait(void);

/* Poll at most max_polls times. Return ZX_OK upon observing idle or
 * ZX_TIMEOUT when the budget runs out, including a zero budget. */
zx_status_t ts_dma_wait_polls(uint16_t max_polls) __z88dk_fastcall;

#endif
