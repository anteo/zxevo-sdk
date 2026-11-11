#ifndef ZX_TEST_H
#define ZX_TEST_H

/* Test steps, assertions and output channels over the ZXHost mailbox. */
#include <stdint.h>

/* Start the harness with interrupts disabled. The target adapter initializes
 * its own hardware and library state after this call. */
void zx_test_init(void);

/* Record an initialization error for the final report. */
void zx_test_error(const char *message);

/* Step terminators complete the current step and wait for the host before
 * returning. `name` is optional and becomes the file tag: NULL or an empty
 * string uses "out". A marker records an assertion-only step without output. */
void zx_test_step_marker(const char *name);
void zx_test_step_shot(const char *name);

/* Finish the current step with a data payload.  The host reads length bytes
 * from the already mapped CPU address and compares a canonical hex dump with
 * the expected .txt file.  The buffer must stay mapped while the host reads it
 * (static/BSS, stack, rodata or the current screen window are fine; a window
 * that the test remaps before the host answers is not).  Length is uint16_t. */
void zx_test_step_data(const char *name, const void *data, uint16_t length);

/* Same step, but the host compares the raw bytes with a .bin golden instead of
 * a reviewable hex dump.  Use it for large buffers. */
void zx_test_step_binary(const char *name, const void *data, uint16_t length);

/* Text output channel.  Build a string with zx_test_output_* (512-byte buffer,
 * truncated on overflow) and finish the step with zx_test_step_text(); the host
 * compares the raw bytes with a .txt file. */
void zx_test_output_begin(void);
void zx_test_output(const char *text);
void zx_test_output_char(char character);
void zx_test_output_u16(uint16_t value);
void zx_test_output_hex8(uint8_t value);
void zx_test_output_hex16(uint16_t value);
void zx_test_step_text(const char *name);

/* Finish the current step without a screenshot or payload; the host records a
 * SKIP. */
void zx_test_step_skip(const char *name, const char *reason);

/* Finish the test: report the accumulated result and leave the CPU spinning. */
void zx_test_finish(void);

/* Record a failed check.  Only the first pending assertion is
 * included in the step log. */
void zx_test_fail(uint16_t line, const char *expression);

#define ZX_ASSERT(condition)                                                                       \
    do {                                                                                           \
        if (!(condition)) zx_test_fail((uint16_t)__LINE__, #condition);                            \
    } while (0)

#endif
