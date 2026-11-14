#include <intrinsic.h>
#include <stdint.h>
#include <zx_host.h>

#include "zx_test.h"

#define ZX_TEST_PASS 0u
#define ZX_TEST_FAIL 1u
#define ZX_TEST_SKIP 2u
#define ZX_TEST_FLAG_SHOT 0x01u
#define ZX_TEST_FLAG_MORE 0x02u
#define ZX_TEST_FLAG_DATA 0x04u
#define ZX_TEST_FLAG_BEGIN 0x08u
#define ZX_TEST_TEXT_CAPACITY 512u

static uint8_t zx_test_sequence;
static uint8_t zx_test_step;
static uint8_t zx_test_step_open;
static uint8_t zx_test_status;
static uint8_t zx_test_fail_pending;
static uint16_t zx_test_fail_line;
static const char *zx_test_fail_expression;
static char zx_test_text_buffer[ZX_TEST_TEXT_CAPACITY];
static uint16_t zx_test_text_length;

static const char *zx_test_name(const char *name) {
    return name && *name ? name : "out";
}

static void zx_test_log_u16(uint16_t value) {
    char digits[5];
    uint8_t count = 0;
    if (!value) {
        zx_host_log_char('0');
        return;
    }
    while (value && count < sizeof(digits)) {
        digits[count++] = (char)('0' + value % 10u);
        value /= 10u;
    }
    while (count) zx_host_log_char((uint8_t)digits[--count]);
}

/* Wait until the host publishes the next request, then reset the step log. */
static void zx_test_next_request(void) {
    while (zx_host_get_request().sequence == zx_test_sequence) {
    }
    zx_test_sequence = zx_host_get_request().sequence;
    zx_host_init();
}

static void zx_test_log_failure(uint8_t new_line) {
    if (!zx_test_fail_pending) return;
    if (new_line) zx_host_log_char('\n');
    zx_host_log_text("line=");
    zx_test_log_u16(zx_test_fail_line);
    zx_host_log_char(' ');
    zx_host_log_text(zx_test_fail_expression);
    zx_test_fail_pending = 0;
}

void zx_test_step_begin(const char *name) {
    zx_host_log_init();
    zx_host_log_text(zx_test_name(name));
    zx_host_set_results(ZX_TEST_PASS, zx_test_step, ZX_TEST_FLAG_BEGIN | ZX_TEST_FLAG_MORE, 0);
    zx_host_finish(ZX_HOST_DONE, 0);
    zx_test_next_request();
    zx_test_step_open = 1;
}

static void zx_test_end_step(uint8_t status, uint8_t flags) {
    zx_host_set_results(status, zx_test_step, (uint8_t)(flags | ZX_TEST_FLAG_MORE), 0);
    zx_host_finish(ZX_HOST_DONE, 0);
    zx_test_next_request();
    zx_test_step_open = 0;
    ++zx_test_step;
}

static void zx_test_step_log(const char *name) {
    zx_host_log_init();
    if (!zx_test_step_open) zx_host_log_text(zx_test_name(name));
}

static void zx_test_complete_step(uint8_t flags, const char *name) {
    zx_test_step_log(name);
    zx_test_log_failure(!zx_test_step_open);
    zx_test_end_step(zx_test_status, flags);
}

void zx_test_init(void) {
    intrinsic_di();
    /* The host seeds the first request before it starts the CPU.  Preserve its
     * sequence across zx_host_init(), which only resets results and the log. */
    zx_test_sequence = zx_host_get_request().sequence;
    zx_host_init();
    zx_test_step = 0;
    zx_test_step_open = 0;
    zx_test_status = ZX_TEST_PASS;
    zx_test_fail_pending = 0;
}

void zx_test_error(const char *message) {
    zx_test_status = ZX_TEST_FAIL;
    zx_host_log_text(message);
}

static void zx_test_data_step(const char *name, uint16_t address, uint16_t length, uint8_t kind,
                              uint8_t flags) {
    zx_test_step_log(name);
    zx_host_log_text(zx_test_step_open ? "DATA " : "\nDATA ");
    zx_test_log_u16(address);
    zx_host_log_char(' ');
    zx_test_log_u16(length);
    zx_host_log_char(' ');
    zx_test_log_u16(kind);
    zx_test_log_failure(1);
    zx_test_end_step(zx_test_status, flags);
}

void zx_test_step_data(const char *name, const void *data, uint16_t length) {
    zx_test_data_step(name, (uint16_t)(uintptr_t)data, length, 0, ZX_TEST_FLAG_DATA);
}

void zx_test_step_binary(const char *name, const void *data, uint16_t length) {
    zx_test_data_step(name, (uint16_t)(uintptr_t)data, length, 2, ZX_TEST_FLAG_DATA);
}

void zx_test_output_begin(void) {
    zx_test_text_length = 0;
    zx_test_text_buffer[0] = 0;
}

void zx_test_output_char(char character) {
    if (zx_test_text_length + 1u >= ZX_TEST_TEXT_CAPACITY) return;
    zx_test_text_buffer[zx_test_text_length++] = character;
    zx_test_text_buffer[zx_test_text_length] = 0;
}

void zx_test_output(const char *text) {
    while (text && *text) zx_test_output_char(*text++);
}

void zx_test_output_u16(uint16_t value) {
    char digits[5];
    uint8_t count = 0;
    if (!value) {
        zx_test_output_char('0');
        return;
    }
    while (value && count < sizeof(digits)) {
        digits[count++] = (char)('0' + value % 10u);
        value /= 10u;
    }
    while (count) zx_test_output_char(digits[--count]);
}

void zx_test_output_hex8(uint8_t value) {
    static const char hex[] = "0123456789ABCDEF";
    zx_test_output_char(hex[(value >> 4) & 0x0Fu]);
    zx_test_output_char(hex[value & 0x0Fu]);
}

void zx_test_output_hex16(uint16_t value) {
    zx_test_output_hex8((uint8_t)(value >> 8));
    zx_test_output_hex8((uint8_t)value);
}

void zx_test_step_text(const char *name) {
    zx_test_data_step(name, (uint16_t)(uintptr_t)zx_test_text_buffer, zx_test_text_length, 1,
                      ZX_TEST_FLAG_DATA);
}

void zx_test_step_toml(const char *name) {
    zx_test_data_step(name, (uint16_t)(uintptr_t)zx_test_text_buffer, zx_test_text_length, 3,
                      ZX_TEST_FLAG_DATA);
}

void zx_test_fail(uint16_t line, const char *expression) {
    zx_test_status = ZX_TEST_FAIL;
    if (!zx_test_fail_pending) {
        zx_test_fail_pending = 1;
        zx_test_fail_line = line;
        zx_test_fail_expression = expression;
    }
}

void zx_test_step_shot(const char *name) {
    zx_test_complete_step(ZX_TEST_FLAG_SHOT, name);
}

void zx_test_step_marker(const char *name) {
    zx_test_complete_step(0, name);
}

void zx_test_step_skip(const char *name, const char *reason) {
    zx_test_step_log(name);
    zx_test_log_failure(!zx_test_step_open);
    zx_host_log_text("\nSKIP ");
    zx_host_log_text(reason);
    zx_test_end_step(ZX_TEST_SKIP, 0);
}

void zx_test_finish(void) {
    zx_host_log_text(zx_test_status == ZX_TEST_PASS ? "\nPASS\n" : "\nFAIL:\n");
    zx_test_log_failure(0);
    zx_host_set_results(zx_test_status, zx_test_step, 0, 0);
    zx_host_finish(ZX_HOST_DONE, 0);
    for (;;) {
    }
}
