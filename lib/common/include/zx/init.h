#ifndef ZX_INIT_H
#define ZX_INIT_H

#include <zx/status.h>

/* Prepare the linked platform library without changing hardware mappings
 * or the display. The SDK CRT calls this before main by default. For manual
 * startup, set up the stack and any BaseConf readback or pinned-window
 * overrides first. TSConf needs no global initialization. */
zx_status_t zx_init(void);

/* Invalidate the prepared paging/drawing state without changing hardware
 * mappings or the display. The SDK CRT calls this on exit by default.
 * Return ZX_BUSY while a window lease or graphics group is active. */
zx_status_t zx_shutdown(void);

#endif
