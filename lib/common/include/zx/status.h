#ifndef ZX_STATUS_H
#define ZX_STATUS_H

/* The numeric values are part of the C/ASM ABI. */
typedef enum {
    ZX_OK = 0,
    ZX_INVALID_ARGUMENT = 1,
    ZX_BUSY = 2,
    ZX_UNAVAILABLE = 3,
    ZX_NOT_INITIALIZED = 4,
    ZX_UNSUPPORTED = 5,
    ZX_UNSAFE_CONTEXT = 6,
    ZX_TIMEOUT = 7,
    ZX_IO_ERROR = 8
} zx_status_t;

#endif
