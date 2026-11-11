#ifndef ZX_IDE_H
#define ZX_IDE_H

#include <stdint.h>
#include <zx/status.h>

/* Direct Nemo IDE access on BaseConf and on TSConf FPGA builds with IDE_HDD. */
typedef enum {
    ZX_ATA_BUSY = 0x80,
    ZX_ATA_READY = 0x40,
    ZX_ATA_DEVICE_FAULT = 0x20,
    ZX_ATA_DRQ = 0x08,
    ZX_ATA_ERROR = 0x01
} zx_ata_status_flag_t;
typedef enum { ZX_ATA_READ, ZX_ATA_WRITE } zx_ata_sector_op_t;
typedef struct {
    uint8_t value;
} zx_ata_status_t;
typedef struct {
    uint32_t lba28_sectors;
    char serial[21];
    char firmware[9];
    char model[41];
} zx_ata_info_t;

/* Read alternate ATA status from base:C8 (xxC8), without acknowledging IRQ. */
zx_status_t zx_ide_alternate_status(uint8_t base, zx_ata_status_t *status);
/* Read exactly 512 bytes from Nemo IDE data port xx10. data_port must be 10h;
 * reset_address must address another IDE register (low byte != 10h), read first
 * to reset low/high-byte alternation. Requires a non-NULL writable 512-byte
 * buffer. Does not issue an ATA command or wait for DRQ; prepare the device
 * first. Returns ZX_INVALID_ARGUMENT for invalid arguments, otherwise ZX_OK. */
zx_status_t zx_ide_read_block(uint8_t data_port, uint16_t reset_address, void *buffer);
/* Nemo ATA operations use device 0, LBA28 and 512-byte logical sectors. Keep
 * buffers mapped throughout and serialize access to the task file and data
 * port, including from interrupt handlers. max_polls is a nonzero bound per
 * status wait. Returns ZX_UNAVAILABLE for floating bus (FFh), ZX_TIMEOUT on
 * poll exhaustion, ZX_IO_ERROR for ATA ERR/DF and ZX_INVALID_ARGUMENT for
 * invalid parameters. A timed-out command may still be active on the device. */
zx_status_t zx_ide_read_sector(uint32_t lba, void *buffer, uint16_t max_polls);
zx_status_t zx_ide_write_sector(uint32_t lba, const void *buffer, uint16_t max_polls);
/* Transfer count consecutive sectors. The entire buffer must be resident
 * and must fit in the CPU address space. On failure earlier sectors may
 * already have been transferred. */
zx_status_t zx_ide_read_sectors(uint32_t lba, void *buffer, uint8_t count, uint16_t max_polls);
zx_status_t zx_ide_write_sectors(uint32_t lba, const void *buffer, uint8_t count,
                                 uint16_t max_polls);
/* Read the 512-byte ATA IDENTIFY DEVICE response in little-endian word order. */
zx_status_t zx_ide_identify(void *buffer, uint16_t max_polls);
/* Read and decode ATA identification using a separate caller-owned 512-byte
 * scratch buffer. Returns ZX_UNSUPPORTED when the drive lacks LBA support.
 * The strings are NUL-terminated with trailing spaces removed. */
zx_status_t zx_ide_get_info(zx_ata_info_t *info, uint8_t scratch[512], uint16_t max_polls);
/* Flush the ATA write cache and wait for command completion. */
zx_status_t zx_ide_flush(uint16_t max_polls);
/* Issue a one-sector command and wait for DRQ. After ZX_OK, transfer exactly
 * one sector using the word or block API, then call zx_ide_wait_complete. */
zx_status_t zx_ide_start_sector(zx_ata_sector_op_t operation, uint32_t lba, uint16_t max_polls);
/* Poll alternate status until BSY clears and DRQ is asserted. */
zx_status_t zx_ide_wait_data(uint16_t max_polls) __z88dk_fastcall;
/* Poll alternate status until BSY and DRQ clear, then acknowledge ATA IRQ. */
zx_status_t zx_ide_wait_complete(uint16_t max_polls) __z88dk_fastcall;
/* Read a 16-bit IDE word: low byte at io_address, then high byte at
 * io_address+1. No readiness polling or byte-phase reset is performed.
 * Returns ZX_INVALID_ARGUMENT for NULL value, otherwise ZX_OK. */
zx_status_t zx_ide_read_word(uint16_t io_address, uint16_t *value);
/* Read ATA status from base:F0 (xxF0). base is the high byte of the port. */
zx_status_t zx_ide_status(uint8_t base, zx_ata_status_t *status);
/* Write exactly 512 bytes to Nemo IDE data port xx10 from a non-NULL readable
 * buffer. data_port/reset_address requirements and status values are the same
 * as zx_ide_read_block. Does not issue an ATA command or wait for DRQ/completion. */
zx_status_t zx_ide_write_block(uint8_t data_port, uint16_t reset_address, const void *buffer);
/* Write a 16-bit IDE word: high byte at io_address+1, then low byte at
 * io_address. Does not wait for readiness; returns ZX_OK. */
zx_status_t zx_ide_write_word(uint16_t io_address, uint16_t value);

#endif
