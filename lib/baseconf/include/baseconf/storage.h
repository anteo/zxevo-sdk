#ifndef BASECONF_STORAGE_H
#define BASECONF_STORAGE_H
#include <stdint.h>
#include <baseconf.h>
#include <zx/fdd.h>

/* BaseConf-specific floppy controls. See <zx/fdd.h> for direct VG93 access
 * and <baseconf/ers.h> for ROM-backed device, FAT and floppy-mounter services. */

/* FE overlay bits 0..3 select drives A..D. The three overlay calls mask INT;
 * the caller must exclude NMI and FDD activity while they run. */
/* Read the four-bit overlay mask. Returns ZX_INVALID_ARGUMENT for NULL mask
 * and ZX_UNAVAILABLE when BaseConf port readback is absent. */
zx_status_t bc_fdd_overlay_get(uint8_t *mask);
/* Probe writable overlay-mask hardware with 05h/0Ah patterns, then restore the
 * old mask. Returns ZX_OK if supported, ZX_UNAVAILABLE if absent/unsupported,
 * or ZX_UNSAFE_CONTEXT if the original mask cannot be restored. */
zx_status_t bc_fdd_overlay_probe(void);
/* Write overlay mask 0..15 and check readback, attempting to restore the old
 * mask on mismatch. Returns ZX_INVALID_ARGUMENT for upper bits, ZX_UNAVAILABLE
 * if readback is absent, or ZX_UNSAFE_CONTEXT if the requested mask is not read back. */
zx_status_t bc_fdd_overlay_set(uint8_t mask);
/* Select FDD drive A..D while preserving side, head-ready and reset via
 * BaseConf's FFh readback. Temporarily close and restore xx77 palette writes. */
zx_status_t bc_fdd_select(zx_fdd_drive_t drive);
/* FE exit is a no-return continuation: this emits exactly OUT (0xBE),A; the
 * next M1 is fetched from ROM at this address. Use only in FE emulator ASM/C
 * whose continuation is intentionally the ROM continuation. */
#define BASECONF_FDD_OVERLAY_EXIT_ASM() __asm out(0xbeh), a __endasm

#endif
