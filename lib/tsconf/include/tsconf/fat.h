#ifndef TSCONF_FAT_H
#define TSCONF_FAT_H

#include <stdint.h>
#include <zx/status.h>

#define TS_FAT_SECTOR_SIZE 512u
#define TS_FAT_FILE 0x00u
#define TS_FAT_DIRECTORY 0x10u
#define TS_FAT_IDE_MASTER 0u
#define TS_FAT_IDE_SLAVE 1u

/* ROM FENTRY record. Use TS_FAT_FILE or TS_FAT_DIRECTORY and an uppercase,
 * NUL-terminated 8.3 name without a path. */
typedef struct {
    uint8_t type;
    char name[13];
} ts_fat_name_t;

/* All calls require the stock TS-BIOS ROM (logical page 0) in W0, with
 * VDOS and DivMMC inactive. Disable interrupts before changing W0 and set
 * Page0=0 and MemConfig=TS_MEM_W0_DIRECT for direct ROM mapping.
 * TS-BIOS temporarily maps RAM page F7h in W2
 * (8000h..BFFFh) for its workspace and stack. Reserve F7h and keep caller
 * code, return stack and any input buffers read by the ROM outside W2.
 * The ROM restores Page2 and SP, sets SysConfig to 02h (14 MHz, caches
 * disabled), and leaves maskable interrupts disabled. The caller owns
 * the single TS-FAT stream, its storage interface and an idle DMA engine.
 * On FDR builds, keep DMANumH (2CAFh) at zero for the ROM's DMA calls.
 * The ROM may wait indefinitely for unresponsive media. */

/* Initialize the SD1 stream at the root of a supported FAT32 partition.
 * Return ZX_OK or ZX_IO_ERROR for a ROM failure. */
zx_status_t ts_fat_mount_sd(void);

/* Initialize the single stream on a Nemo IDE drive at the root of a FAT32
 * partition. Use TS_FAT_IDE_MASTER or TS_FAT_IDE_SLAVE. Enable frame IRQ
 * before calling so the ROM can wait for drive initialization in IM 2.
 * Use the project-built ROM for the slave's LBA selector fix.
 * Return ZX_INVALID_ARGUMENT for an invalid drive or ZX_IO_ERROR for a ROM failure. */
zx_status_t ts_fat_mount_ide(uint8_t drive) __z88dk_fastcall;

/* Open a file in the current directory and position the stream at its start.
 * On ZX_OK write the length in bytes to *size. Leave *size unchanged on
 * ZX_INVALID_ARGUMENT or ZX_IO_ERROR (ROM rejected the lookup). Keep name outside W2.
 * Only read after a successful open, since a failed search can move the
 * stream cursor. */
zx_status_t ts_fat_open(const ts_fat_name_t *name, uint32_t *size);

/* Read the next 512-byte sector of an open file into the given physical
 * RAM page at an even offset in 0..3E00h. Exclude F7h and live code, data
 * and stack from the destination and use uncached CPU aliases to read it.
 * Use the file length to bound reads and count valid bytes in the final
 * sector. The stock ROM has no reliable READ512 status on return. */
void ts_fat_read_sector(uint8_t page, uint16_t offset);

/* Write the next 512-byte sector from physical RAM, with the same page,
 * offset and cache requirements as read. The file must already exist and
 * the write must fit its allocated chain. The ROM has no reliable WRITE512
 * status. The caller supplies padding for a partial final sector. */
void ts_fat_write_sector(uint8_t page, uint16_t offset);

/* Reset an open file's cursor or advance it by up to count sectors. Count
 * zero is a no-op. Bound the skip by the known file length. */
void ts_fat_rewind(void);
void ts_fat_skip_sectors(uint8_t count) __z88dk_fastcall;

/* Select the root directory. Reopen a file before reading or writing. */
void ts_fat_set_root(void);
/* Find a TS_FAT_DIRECTORY name in the current directory and enter it.
 * Return ZX_INVALID_ARGUMENT for an invalid record or ZX_IO_ERROR if the
 * ROM rejects the lookup.
 * Use a directory record named ".." to go up. Reopen any file afterward. */
zx_status_t ts_fat_set_directory(const ts_fat_name_t *name) __z88dk_fastcall;

/* Create a new file of nonzero byte length and position the cursor at its
 * start. Create a directory with an ordinary uppercase 8.3 name string.
 * For both operations, supply a name that does not exist, in resident
 * memory outside W2. Return ZX_INVALID_ARGUMENT for invalid inputs or ZX_IO_ERROR on ROM failure. */
zx_status_t ts_fat_create_file(const ts_fat_name_t *name, uint32_t size);
zx_status_t ts_fat_create_directory(const char *name) __z88dk_fastcall;
/* Delete an ordinary file in the current directory. Return ZX_INVALID_ARGUMENT
 * for an invalid record or ZX_IO_ERROR on ROM failure. */
zx_status_t ts_fat_delete_file(const ts_fat_name_t *name) __z88dk_fastcall;

#endif
