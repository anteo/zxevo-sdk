#ifndef BASECONF_FONT_H
#define BASECONF_FONT_H

#include <stdint.h>
#include <zx/status.h>

/* Upload a raw 2 KiB hardware font as bc_upload_font_to does, but save and
 * restore the RAM bytes at destination. The uploaded hardware font remains.
 * destination has the same W1..W3/0800h alignment requirements as below.
 * backup is a separate 2 KiB writable RAM region in W0..W3; no alignment is needed.
 * All three CPU ranges must be non-null, fit below 10000h and be disjoint.
 * The caller guarantees writable RAM for backup, no physical aliases between
 * the three ranges, and no code, stack or data needed by this call in either
 * written buffer. Do not use selected draw-surface pages for either buffer.
 * Mappings remain stable and NMI is excluded throughout the call.
 * INT is masked around backup/upload/restore and its prior state is restored.
 * BF.2 is cleared before destination is restored; backup retains the saved bytes.
 * Returns ZX_INVALID_ARGUMENT for invalid CPU ranges/alignment, ZX_BUSY if BF.2
 * is already set, otherwise ZX_OK. Physical mappings are not inspected. */
zx_status_t bc_upload_font_preserving(const uint8_t font[2048], uint8_t *destination,
                                      uint8_t backup[2048]);
/* Upload raw 2 KiB font data through BF.2 using the current CPU memory map.
 * font is readable; destination is disposable writable RAM in W1..W3, aligned
 * to 0800h. Both CPU ranges must be non-null, fit below 10000h and be disjoint.
 * The caller guarantees valid physical mappings, no physical overlap between
 * source/destination, and no code, stack or data needed by this call in destination.
 * Do not use selected draw-surface pages for destination. Keep mappings stable
 * and exclude NMI throughout the call: BF.2 mirrors every CPU memory write into
 * font RAM. INT is masked during upload and its prior state is restored.
 * Returns ZX_INVALID_ARGUMENT for invalid CPU ranges/alignment, ZX_BUSY if BF.2
 * is already set, otherwise ZX_OK. Physical mappings are not inspected and
 * library initialization is not required. */
zx_status_t bc_upload_font_to(const uint8_t font[2048], uint8_t *destination);

#endif
