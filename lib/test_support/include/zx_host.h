#ifndef ZX_HOST_H
#define ZX_HOST_H

#include <stdint.h>
#include "zx_host_config.h"

typedef struct {
    uint8_t command;
    uint8_t arg0;
    uint8_t arg1;
    uint8_t sequence; /* request identifier, also retained in the result header */
} zx_host_request_t;

enum {
    ZX_HOST_IDLE = ZX_HOST_STATE_IDLE,
    ZX_HOST_DONE = ZX_HOST_STATE_DONE,
    ZX_HOST_ABORTED = ZX_HOST_STATE_ABORTED,
    ZX_HOST_ERROR = ZX_HOST_STATE_ERROR
};

/* Initialize result metadata/log without changing the published request. */
void zx_host_init(void);
zx_host_request_t zx_host_get_request(void);
uint8_t zx_host_cancelled(void);
void zx_host_set_results(uint8_t result0, uint8_t result1, uint8_t result2, uint8_t result3);
void zx_host_finish(uint8_t state, uint8_t flags);

/* Bounded NUL-terminated diagnostic channel, separate from result fields. */
void zx_host_log_init(void);
void zx_host_log_char(uint8_t ch);
void zx_host_log_text(const char *text);

#endif
