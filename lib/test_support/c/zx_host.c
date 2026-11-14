#include <stdint.h>
#include "zx_host.h"
#include "zx_host_config.h"

static volatile uint8_t *const mailbox = (volatile uint8_t *)(uintptr_t)ZX_HOST_HEADER_ADDRESS;
static volatile uint8_t *const log_buffer = (volatile uint8_t *)(uintptr_t)ZX_HOST_LOG_ADDRESS;
static uint16_t log_cursor;

void zx_host_init(void) {
    mailbox[ZX_HOST_FIELD_MAGIC + 0] = ZX_HOST_MAGIC_0;
    mailbox[ZX_HOST_FIELD_MAGIC + 1] = ZX_HOST_MAGIC_1;
    mailbox[ZX_HOST_FIELD_MAGIC + 2] = ZX_HOST_MAGIC_2;
    mailbox[ZX_HOST_FIELD_MAGIC + 3] = ZX_HOST_MAGIC_3;
    mailbox[ZX_HOST_FIELD_VERSION] = ZX_HOST_PROTOCOL_VERSION;
    mailbox[ZX_HOST_FIELD_STATE] = ZX_HOST_STATE_IDLE;
    mailbox[ZX_HOST_FIELD_FLAGS] = 0;
    mailbox[ZX_HOST_FIELD_RESULT0] = 0;
    mailbox[ZX_HOST_FIELD_RESULT1] = 0;
    mailbox[ZX_HOST_FIELD_RESULT2] = 0;
    mailbox[ZX_HOST_FIELD_RESULT3] = 0;
    zx_host_log_init();
}

zx_host_request_t zx_host_get_request(void) {
    zx_host_request_t request;
    request.command = mailbox[ZX_HOST_FIELD_COMMAND];
    request.arg0 = mailbox[ZX_HOST_FIELD_ARG0];
    request.arg1 = mailbox[ZX_HOST_FIELD_ARG1];
    request.sequence = mailbox[ZX_HOST_FIELD_SEQUENCE];
    return request;
}

uint8_t zx_host_cancelled(void) {
    return mailbox[ZX_HOST_FIELD_CANCEL] != 0;
}

void zx_host_set_results(uint8_t result0, uint8_t result1, uint8_t result2, uint8_t result3) {
    mailbox[ZX_HOST_FIELD_RESULT0] = result0;
    mailbox[ZX_HOST_FIELD_RESULT1] = result1;
    mailbox[ZX_HOST_FIELD_RESULT2] = result2;
    mailbox[ZX_HOST_FIELD_RESULT3] = result3;
}

void zx_host_finish(uint8_t state, uint8_t flags) {
    if (state != ZX_HOST_STATE_DONE && state != ZX_HOST_STATE_ABORTED &&
        state != ZX_HOST_STATE_ERROR)
        state = ZX_HOST_STATE_ERROR;
    mailbox[ZX_HOST_FIELD_STATE] = ZX_HOST_STATE_IDLE;
    mailbox[ZX_HOST_FIELD_FLAGS] = flags;
    mailbox[ZX_HOST_FIELD_VERSION] = ZX_HOST_PROTOCOL_VERSION;
    mailbox[ZX_HOST_FIELD_MAGIC + 0] = ZX_HOST_MAGIC_0;
    mailbox[ZX_HOST_FIELD_MAGIC + 1] = ZX_HOST_MAGIC_1;
    mailbox[ZX_HOST_FIELD_MAGIC + 2] = ZX_HOST_MAGIC_2;
    mailbox[ZX_HOST_FIELD_MAGIC + 3] = ZX_HOST_MAGIC_3;
    mailbox[ZX_HOST_FIELD_STATE] = state;
}

void zx_host_log_init(void) {
    uint16_t i;
    for (i = 0; i < ZX_HOST_LOG_SIZE; ++i) log_buffer[i] = 0;
    log_cursor = 0;
}

void zx_host_log_char(uint8_t ch) {
    if (ch && log_cursor + 1u < ZX_HOST_LOG_SIZE) {
        log_buffer[log_cursor++] = ch;
        log_buffer[log_cursor] = 0;
    }
}

void zx_host_log_text(const char *text) {
    if (!text) return;
    while (*text) zx_host_log_char((uint8_t)*text++);
}
