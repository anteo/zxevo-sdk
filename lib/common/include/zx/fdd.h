#ifndef ZX_FDD_H
#define ZX_FDD_H

#include <stdint.h>
#include <zx/status.h>

#define ZX_FDD_DRQ 0x40u
#define ZX_FDD_INTRQ 0x80u

typedef enum { ZX_FDD_DRIVE_A, ZX_FDD_DRIVE_B, ZX_FDD_DRIVE_C, ZX_FDD_DRIVE_D } zx_fdd_drive_t;
typedef enum { ZX_FDD_COMMAND, ZX_FDD_TRACK, ZX_FDD_SECTOR, ZX_FDD_DATA } zx_fdd_reg_t;

typedef struct {
    zx_fdd_drive_t drive;
    uint8_t side, hrdy, reset;
} zx_fdd_system_t;

/* Serialize direct Beta Disk access with disk handlers. On TSConf, open
 * the ports via DOS or FDDVirt and keep the selected drive physical.
 * When changing drives, the destination must also be physical. DOS
 * accesses to a virtual drive can switch W0 to VDOS.
 * On BaseConf the library enables and restores shadow ports. Exclude NMI. */

/* Read or write a VG93 register. Reading ZX_FDD_COMMAND returns
 * controller status and acknowledges INTRQ. Invalid registers or a NULL
 * read output return ZX_INVALID_ARGUMENT. BaseConf also masks INT and
 * can return ZX_BUSY (BF.2 set), ZX_UNSAFE_CONTEXT (FE overlay enabled),
 * or ZX_UNAVAILABLE (readback absent). The output changes only on success. */
zx_status_t zx_fdd_reg_read(zx_fdd_reg_t reg, uint8_t *value);
zx_status_t zx_fdd_reg_write(zx_fdd_reg_t reg, uint8_t value);

/* Read the Beta Disk system byte at FFh. D6 and D7 are DRQ and INTRQ.
 * The lower bits are platform-specific. Return ZX_INVALID_ARGUMENT for NULL. */
zx_status_t zx_fdd_status(uint8_t *status) __z88dk_fastcall;
/* Write the system latch. side is the software D4 value, inverted on
 * the physical pin. side, hrdy and reset are 0 or 1; reset=1 asserts
 * reset. Return ZX_INVALID_ARGUMENT for NULL or an invalid field. BaseConf
 * masks INT and temporarily closes and restores palette writes. It can
 * return ZX_BUSY (BF.2 set), ZX_UNAVAILABLE (readback absent) or
 * ZX_UNSAFE_CONTEXT (palette gate could not be closed or restored). */
zx_status_t zx_fdd_system_write(const zx_fdd_system_t *cfg) __z88dk_fastcall;

#endif
