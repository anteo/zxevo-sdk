#ifndef BASECONF_ERS_H
#define BASECONF_ERS_H

#include <stdint.h>
#include <baseconf.h>

/* ERS wrappers call RST 08h in the caller's memory/ROM context. Declare a usable
 * profile with bc_ers_set_profile and arrange the required ROM, RAM and BASIC
 * state before calling; wrappers do not probe services or prepare that state.
 * BC_ERS_NONE returns ZX_UNAVAILABLE. ZX_OK means the service returned, not that
 * its device/FAT operation succeeded: inspect result fields where provided.
 * Other firmware flags are not translated to zx_status_t. Buffers must be large
 * enough and accessible to the service; sizes and contents are not checked.
 * Required NULL pointers return ZX_INVALID_ARGUMENT; documented optional NULLs
 * are accepted. Selector/subfunction numbers below are hexadecimal. */

/* VERSION returns packed BCDE and A verbatim. flags is A, not the CPU F byte;
 * decode the version and feature bits according to the installed ERS. */
typedef struct {
    uint8_t b, c, d, e, flags;
} bc_ers_version_t;

/* Result of ERS 50h/00h device and partition discovery. */
typedef struct {
    uint8_t current_partition;
    uint8_t partition_count;
    uint8_t fat_type;
    uint8_t found;
} bc_ers_device_info_t;

typedef struct {
    /* IX receiver after the hook; DE remaining length; flags are the returned F byte. */
    uint16_t receiver;
    uint16_t remaining;
    uint8_t flags;
} bc_ers_tape_result_t;

/* Read or write direction for a Nemo sector transfer. */
typedef enum { BC_ERS_TRANSFER_READ = 0, BC_ERS_TRANSFER_WRITE = 1 } bc_ers_transfer_direction_t;

/* Nemo transfer status and the positions returned by the driver. */
typedef struct {
    uint8_t device_status;
    /* BCDE on return; the bundled driver preserves the requested starting LBA. */
    uint32_t sector;
    /* HL on return; points after the bytes transferred, including partial errors. */
    void *next_buffer;
} bc_ers_nemo_transfer_result_t;

/* 51h/05 result: directory entry index and the service's CF result. */
typedef struct {
    uint16_t directory_entry;
    uint8_t not_found;
} bc_ers_fat_search_result_t;

/* 51h/09 result: advanced buffer address and CF end/error indicator. */
typedef struct {
    uint16_t next_address;
    uint8_t carry;
} bc_ers_fat_read_result_t;

/* 51h/0B position operations. */
typedef enum {
    BC_ERS_FAT_POSITION_SAVE = 0,
    BC_ERS_FAT_POSITION_RESTORE = 1,
    BC_ERS_FAT_POSITION_FIRST = 2,
    BC_ERS_FAT_POSITION_BACK = 3,
    BC_ERS_FAT_POSITION_FORWARD = 4,
    BC_ERS_FAT_POSITION_COUNT = 5,
    BC_ERS_FAT_POSITION_SELECT = 6,
    BC_ERS_FAT_POSITION_GET = 7
} bc_ers_fat_position_operation_t;

/* Opaque 64-byte descriptor copied by 53h/03. */
typedef struct {
    uint8_t bytes[64];
} bc_ers_mounted_image_t;

/* 51h/06 results; list bytes remain in the ERS-owned RAM buffer. */
typedef struct {
    uint16_t count;
    uint8_t ram_sortfiles_page;
} bc_ers_fat_file_list_t;

/* ERS window flags, stored in bc_ers_window_t.flags. */
enum {
    BC_ERS_WINDOW_FILE_LIST = 0x08,
    BC_ERS_WINDOW_NO_TEXT = 0x10,
    BC_ERS_WINDOW_TOP_HEADER = 0x20,
    BC_ERS_WINDOW_NO_FRAME = 0x40,
    BC_ERS_WINDOW_BOTTOM_HEADER = 0x80,
};

/* ERS window selection flags, stored in bc_ers_window_t.selection. */
enum {
    BC_ERS_WINDOW_COUNT_INDIRECT = 0x40,
    BC_ERS_WINDOW_ITEM_INDIRECT = 0x80,
};

typedef struct {
    uint8_t reserved;
    uint8_t x, y;
    uint8_t height, width;
    uint8_t key;
} bc_ers_mouse_zone_t;

/* Native 20-byte Z80 descriptor for selector 46h. Geometry is in character
 * cells and includes the frame. Attributes use the current video mode. */
typedef struct {
    uint8_t x, y;
    uint8_t height, width;
    uint8_t attribute, cursor_attribute;
    uint8_t flags;
    uint8_t selection; /* Menu row in bits 0..5 and BC_ERS_WINDOW_*_INDIRECT flags. */
    uint16_t current_item; /* Item index or Z80 address of a uint16_t. */
    uint16_t item_count;   /* Item count or Z80 address of a uint16_t. */
    const char *text;      /* NUL-terminated ERS control string. */
    const uint16_t *handlers;
    const bc_ers_mouse_zone_t *mouse_zones;
    const uint8_t *hotkeys;
} bc_ers_window_t;

/* Check ERS CMOS settings CRC; restore defaults when it does not match. */
zx_status_t bc_ers_cmos_init(void);

/* Read one raw CMOS byte by index through ERS 55h/01h; index is not validated. */
zx_status_t bc_ers_cmos_read(uint8_t index, uint8_t *value);

/* Force ERS CMOS settings to defaults. */
zx_status_t bc_ers_cmos_reset_defaults(void);

/* Write one CMOS byte through ERS 55h/02h and let ERS update its settings CRC.
 * index/value are passed unchanged; this differs from a raw zx_nvram_write. */
zx_status_t bc_ers_cmos_write(uint8_t index, uint8_t value);

/* 50h/06: check SD availability; bit 0 is built-in SD, bit 1 is NeoGS SD.
 * Firmware may display its card-change/loss UI while checking. */
zx_status_t bc_ers_device_check_sd(uint8_t *availability);

/* 50h/00h: discover/initialize devices and partitions. info->found is 1 when
 * CF=0, 0 when CF=1; ZX_OK alone does not indicate a discovered partition. */
zx_status_t bc_ers_device_find(bc_ers_device_info_t *info);

/* 50h/02h: query the current partition index/count and filesystem type.
 * info->found is the inverted firmware carry flag, as in bc_ers_device_find. */
zx_status_t bc_ers_device_get_current_volume(bc_ers_device_info_t *info);

/* 50h/03: copy the 256-byte partition table. */
zx_status_t bc_ers_device_get_volume_table(uint8_t table[256]);

/* 50h/07h subfunction 02 reads; 03 writes. master_slave is A' bit 0: 0=master,
 * 1=slave (not the device ID in the volume table). Select the Nemo volume first;
 * the bundled read/write driver uses that volume to set ATA device/head.
 * sector is a 32-bit LBA in BCDE; sector_count is the number of 512-byte sectors
 * in A. A zero count means 256 sectors, so the buffer must hold 131072 bytes;
 * use a nonzero count for ordinary buffers. Writes modify the selected device.
 * result receives status A, returned BCDE (the starting LBA in the bundled
 * driver) and next-buffer HL. A status is 0=success, 1=timeout, 6=command error,
 * 7=CD/DVD. ZX_OK means only that ERS returned; inspect result->device_status.
 * Unknown direction or NULL buffer/result returns ZX_INVALID_ARGUMENT. */
zx_status_t bc_ers_device_nemo_transfer(bc_ers_transfer_direction_t direction, uint8_t master_slave,
                                        uint8_t sector_count, uint32_t sector, void *buffer,
                                        bc_ers_nemo_transfer_result_t *result);

/* 50h/09h: set the driver's 48-bit sector number: high supplies bits 47..32,
 * middle bits 31..16, low bits 15..0. Does not transfer any data. */
zx_status_t bc_ers_device_set_sector_number(uint16_t high, uint16_t middle, uint16_t low);

/* 50h/01: select a zero-based FAT partition. */
zx_status_t bc_ers_device_set_volume(uint8_t index);

/* 46h: draw a window and select it for subsequent ERS print and scroll calls.
 * Set the video mode first. For ZX screen 0, map its RAM page at 0x4000.
 * Keep the descriptor in caller RAM at 4000h..7FFFh and the text accessible to
 * ERS. For a plain window, zero the menu fields. To omit text, set
 * BC_ERS_WINDOW_NO_TEXT. */
zx_status_t bc_ers_draw_window(const bc_ers_window_t *window);

/* 51h/02h: enter the directory selected by ERS's current directory entry;
 * selecting '..' moves to its parent. */
zx_status_t bc_ers_fat_enter_directory(void);

/* 51h/06h: build an internal file list using the current extension filter.
 * list receives the count and physical RAM_SORTFILES page; list data is not
 * copied or mapped into the caller's CPU address space. */
zx_status_t bc_ers_fat_find_file_items(bc_ers_fat_file_list_t *list);

/* 51h/05h: find/select a short name such as "FILE.EXT" in the current directory.
 * Supply a NUL-terminated name in a readable buffer of at least 16 bytes: the
 * bundled ERS copies all 16 bytes. result->not_found is the firmware CF bit;
 * directory_entry is meaningful when not_found is zero. ZX_OK can mean not found. */
zx_status_t bc_ers_fat_find_short_name(const char *name, bc_ers_fat_search_result_t *result);

/* 51h/04: copy the selected long name, or its 8.3 name, into a 256-byte buffer. */
zx_status_t bc_ers_fat_get_long_name(char name[256]);

/* 51h/03: copy the current path into a 256-byte buffer. */
zx_status_t bc_ers_fat_get_path(char path[256]);

/* 51h/08: open the selected file for sequential reading. */
zx_status_t bc_ers_fat_open_file(void);

/* 51h/0Bh: save/restore, move or query ERS's current directory position.
 * position is required input/output: its initial value is passed as BC and
 * returned BC replaces it. SELECT takes a directory-entry index; BACK/FORWARD
 * take their step count from the high byte (B), not the low byte.
 * The bundled ERS returns the current position through the common external
 * exit, including for COUNT; do not assume COUNT returns a count here.
 * Initialize *position even for operations that ignore the input. */
zx_status_t bc_ers_fat_position_files(bc_ers_fat_position_operation_t operation,
                                      uint16_t *position);

/* 51h/01h: select a zero-based physical directory-entry index and copy its
 * 32-byte FAT record into entry. This index includes records hidden by filters. */
zx_status_t bc_ers_fat_read_directory_entry(uint16_t index, uint8_t entry[32]);

/* 51h/09h: sequentially read up to sectors 512-byte sectors from the file opened
 * by bc_ers_fat_open_file. Supply enough writable buffer space for the request.
 * result->next_address is returned HL; carry is firmware CF (end/error).
 * ZX_OK does not guarantee that the full requested amount was read. */
zx_status_t bc_ers_fat_read_file(uint8_t sectors, void *buffer, bc_ers_fat_read_result_t *result);

/* 51h/0C: select the root directory of the current partition. */
zx_status_t bc_ers_fat_root_directory(void);

/* 51h/07h: copy up to 16 three-byte extensions, e.g. "TRDSCLTAP", terminated
 * by NUL; NULL clears the filter. For non-NULL input, provide 49 readable bytes:
 * the bundled ERS copies that many even when the sequence ends earlier. */
zx_status_t bc_ers_fat_set_extension_mask(const char *extensions);

/* 52h: sort ERS's existing internal file-search results. */
zx_status_t bc_ers_fat_sort_found_files(void);

/* 4Eh: invoke the firmware file-browser entry. The ROM does not define a
 * return-to-caller or selected-file contract for this entry. */
zx_status_t bc_ers_file_browser_open(void);

/* 54h: unpack/install the FAT boot helper in ERS's work area and copy current
 * FAT variables to destination. The buffer size/layout is firmware-defined
 * (BUF_CURRFATVAR_Size in the bundled ROM); this wrapper does not validate it. */
zx_status_t bc_ers_install_fat_boot_variables(void *destination);

/* 4Ch/00h: store unsigned dividend/divisor in *quotient. divisor must be
 * nonzero; zero is not checked by this wrapper. No remainder is returned. */
zx_status_t bc_ers_math_divide_u16(uint16_t dividend, uint16_t divisor, uint16_t *quotient);

/* 4Ch/02h: divide *dividend by *divisor, storing quotient and remainder.
 * All pointers are required; *divisor must be nonzero (not checked). */
zx_status_t bc_ers_math_divide_u32(const uint32_t *dividend, const uint32_t *divisor,
                                   uint32_t *quotient, uint32_t *remainder);

/* 4Ch/01h: store the full unsigned 16x16-bit product in *product. */
zx_status_t bc_ers_math_multiply_u16(uint16_t left, uint16_t right, uint32_t *product);

/* 4Ch/03h: multiply unsigned *left by right and store the result in *product
 * using the service's full 64-bit register result. Both pointers are required. */
zx_status_t bc_ers_math_multiply_u32_u16(const uint32_t *left, uint16_t right, uint64_t *product);

/* 4Ch/05h: convert unsigned value to NUL-terminated decimal text. output must
 * hold 11 bytes; the service copies 11 bytes even for a shorter number. */
zx_status_t bc_ers_math_u16_to_decimal(uint16_t value, char output[11]);

/* 4Ch/04h: convert unsigned *value to NUL-terminated decimal text.
 * value is required; output must hold the service's full 11-byte copy. */
zx_status_t bc_ers_math_u32_to_decimal(const uint32_t *value, char output[11]);

/* 4Ch/06h: convert unsigned value to NUL-terminated decimal text. output must
 * hold 11 bytes, as with bc_ers_math_u16_to_decimal. */
zx_status_t bc_ers_math_u8_to_decimal(uint8_t value, char output[11]);

/* 53h/08h: set *mounted to 1 when drive 0..3 (A..D) has an image, otherwise 0.
 * Out-of-range drives return ZX_INVALID_ARGUMENT, as in all drive calls below. */
zx_status_t bc_ers_mounter_drive_has_mounted_image(uint8_t drive, uint8_t *mounted);

/* 53h/02: parse IMAGE.MNT and mount the listed images. */
zx_status_t bc_ers_mounter_find_mounted_files(void);

/* 53h/06: copy the 32-byte FAT directory record for the image loaded into RAM disk. */
zx_status_t bc_ers_mounter_get_loaded_file_entry(uint8_t entry[32]);

/* 53h/03: copy four opaque 64-byte mounted-image descriptors. */
zx_status_t bc_ers_mounter_get_mounted_images(bc_ers_mounted_image_t images[4]);

/* 53h/08: get the image/virtual-drive assignment bit fields. */
zx_status_t bc_ers_mounter_get_virtual_drive_bits(uint8_t *bits);

/* 53h/05: load the selected image into its RAM disk or tape buffer. */
zx_status_t bc_ers_mounter_load_current_image(void);

/* 53h/00: mount the selected current FAT file as a drive image. */
zx_status_t bc_ers_mounter_mount_file(uint8_t drive);

/* 53h/01h: transfer one 256-byte image sector for drive 0..3 (A..D).
 * write=0 reads into buffer, nonzero writes from it; track is zero-based and
 * sector starts at 1. Zero sector returns ZX_INVALID_ARGUMENT. ZX_OK does not
 * expose the firmware's transfer-error flags. */
zx_status_t bc_ers_mounter_read_write_mounted(uint8_t drive, uint8_t write, uint8_t track,
                                              uint8_t sector, uint8_t buffer[256]);

/* 53h/0A: persistently select a real drive. */
zx_status_t bc_ers_mounter_set_real_drive(uint8_t drive);

/* 53h/09: assign the same drive as real and virtual. */
zx_status_t bc_ers_mounter_set_virtual_and_real_drive(uint8_t drive);

/* 53h/0B: persistently select a virtual/RAM-disk drive. */
zx_status_t bc_ers_mounter_set_virtual_drive(uint8_t drive);

/* 53h/04: unmount a drive. */
zx_status_t bc_ers_mounter_unmount(uint8_t drive);

/* Lock or unlock the ERS NMI file-browser entry (zero unlocks, nonzero locks). */
zx_status_t bc_ers_nmi_file_browser_lock(uint8_t locked);

/* Print one character in the current ERS window (selector 48h). */
zx_status_t bc_ers_print_char(uint8_t character);

/* 47h: print a NUL-terminated ERS control string. Pass the current window
 * descriptor in caller RAM at 4000h..7FFFh for positioning and centering. */
zx_status_t bc_ers_print_message(const bc_ers_window_t *window, const char *message);

/* Selectors 40h..45h are BASIC hooks and require the corresponding BASIC state. */
/* Initialize the BASIC AY-printer hook (selector 40h). */
zx_status_t bc_ers_printer_init(void);

/* Send a BASIC token to the AY-printer hook (selector 42h). */
zx_status_t bc_ers_printer_put_token(uint8_t token);

/* Send a character (20h..7Fh) to the AY-printer hook (selector 41h). */
zx_status_t bc_ers_printer_write(uint8_t character);

/* 43h: send the ZX bitmap at 4000h to the AY printer when enabled in ERS CMOS.
 * A direct call returns to the caller without clearing the BASIC printer buffer. */
zx_status_t bc_ers_printer_write_screen(void);

/* Call ERS selector 4D and return BCDE/A registers verbatim. */
zx_status_t bc_ers_read_version(bc_ers_version_t *version);

/* 4Ah: shift the supplied window down one character row, leaving the
 * vacated row intact. Keep the descriptor in caller RAM at 4000h..7FFFh.
 * In ZX mode attributes=0 moves the bitmap only and attributes=1 moves
 * attributes too. Text mode always moves both. */
zx_status_t bc_ers_scroll_down(const bc_ers_window_t *window, uint8_t attributes);

/* 49h: scroll the current ERS window up; attributes follows bc_ers_scroll_down. */
zx_status_t bc_ers_scroll_up(const bc_ers_window_t *window, uint8_t attributes);

/* 57h: install built-in ATM font (kind 0), built-in CP866 font (kind 1), or
 * ERS-compressed data (kind 2). data is ignored by the built-in kinds, but this
 * wrapper requires a non-NULL pointer for every kind. Custom data must remain
 * service-readable during the call. kind > 2 returns ZX_INVALID_ARGUMENT. */
zx_status_t bc_ers_set_compressed_font(uint8_t font_kind, const void *data);

/* 4Bh: request=0 queries saved ERS mode bits; nonzero requests update the ERS
 * video/turbo/memory settings using its packed request format. saved_mode is
 * always required and receives returned A, but is defined only for a query.
 * Request bits are passed unchanged and do not use bc_video_mode_t values. */
zx_status_t bc_ers_set_mode(uint8_t request, uint8_t *saved_mode);

/* 56h: install 16 bytes of ERS-format ATM palette data (A=1).
 * Bytes are ordered by palette index from 15 down to 0. */
zx_status_t bc_ers_set_palette(const uint8_t atm_palette[16]);

/* Initialize BASIC tape emulation (selector 44h). */
zx_status_t bc_ers_tape_init(void);

/* 45h: run a BASIC loader step with destination in IX and length in DE.
 * Requires active BASIC tape state and suitable writable destination memory;
 * destination/length are not validated. result is required and receives the
 * returned receiver IX, remaining DE and raw F byte, including carry status. */
zx_status_t bc_ers_tape_load(void *destination, uint16_t length, bc_ers_tape_result_t *result);

#endif
