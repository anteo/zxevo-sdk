#include <zx/printf.h>
#include <limits.h>
#include "../internal.h"

static int zx__va_int(va_list *args) {
    return va_arg(*args, int);
}
static unsigned int zx__va_uint(va_list *args) {
    return va_arg(*args, unsigned int);
}
static const char *zx__va_string(va_list *args) {
    return va_arg(*args, const char *);
}

static int zx__emit(char c, int count) {
    if (count == INT_MAX || zx__printf_write(&c, 1, 0) < 0) return -1;
    return count + 1;
}

/* The backend consumes a prefix up to the next format delimiter or field end. */
static int zx__emit_text(const char **source, uint8_t limit, uint8_t stop, int count) {
    int written = zx__printf_write(*source, limit, stop);
    unsigned int total;
    if (written < 0) return -1;
    total = (unsigned int)count + (unsigned int)written;
    *source += (uint8_t)written;
    return total > INT_MAX ? -1 : (int)total;
}

static int zx__emit_field(const char *text, uint8_t length, uint8_t width, uint8_t left,
                          uint8_t zero, uint8_t negative, int count) {
    uint8_t padding = width > length + negative ? (uint8_t)(width - length - negative) : 0;
    const char *end = text + length;
    uint8_t i;
    if (!left && !zero)
        for (i = 0; i < padding; ++i) {
            count = zx__emit(' ', count);
            if (count < 0) return -1;
        }
    if (negative) {
        count = zx__emit('-', count);
        if (count < 0) return -1;
    }
    if (!left && zero)
        for (i = 0; i < padding; ++i) {
            count = zx__emit('0', count);
            if (count < 0) return -1;
        }
    while (text != end) {
        count = zx__emit_text(&text, (uint8_t)(end - text), 0, count);
        if (count < 0) return -1;
    }
    if (left)
        for (i = 0; i < padding; ++i) {
            count = zx__emit(' ', count);
            if (count < 0) return -1;
        }
    return count;
}

int zx_console_vprintf(const char *format, va_list args) {
    int count = 0;
    if (!format) return -1;
    while (*format) {
        uint8_t width = 0, left = 0, zero = 0;
        char spec;
        if (*format != '%') {
            count = zx__emit_text(&format, UINT8_MAX, '%', count);
            if (count < 0) return -1;
            continue;
        }
        ++format;
        if (*format == '%') {
            ++format;
            count = zx__emit('%', count);
            if (count < 0) return -1;
            continue;
        }
        if (*format == '-') {
            left = 1;
            ++format;
        }
        if (*format == '0') {
            zero = 1;
            ++format;
        }
        while (*format >= '0' && *format <= '9') {
            uint8_t digit = (uint8_t)(*format - '0');
            if (width > 25u || (width == 25u && digit > 5u))
                width = 255u;
            else
                width = (uint8_t)(width * 10u + digit);
            ++format;
        }
        spec = *format;
        if (!spec) {
            count = zx__emit('%', count);
            if (count < 0) return -1;
            break;
        }
        ++format;
        if (spec == 'c') {
            char value = (char)zx__va_int(&args);
            count = zx__emit_field(&value, 1u, width, left, zero, 0u, count);
        } else if (spec == 's') {
            const char *value = zx__va_string(&args);
            uint8_t length = 0;
            if (!value) value = "";
            while (length != UINT8_MAX && value[length]) ++length;
            count = zx__emit_field(value, length, width, left, 0u, 0u, count);
            if (count < 0) return -1;
            if (length == 255u) {
                value += 255u;
                while (*value) {
                    count = zx__emit_text(&value, UINT8_MAX, 0, count);
                    if (count < 0) return -1;
                }
            }
        } else if (spec == 'd' || spec == 'i') {
            int16_t signed_value = (int16_t)zx__va_int(&args);
            uint8_t negative = (uint8_t)(signed_value < 0);
            uint16_t magnitude =
                negative ? (uint16_t)(0u - (uint16_t)signed_value) : (uint16_t)signed_value;
            char digits[5];
            char *end = digits + sizeof(digits);
            uint8_t length = zx__printf_unsigned_string(magnitude, 10u, 0u, end);
            count = zx__emit_field(end - length, length, width, left, zero, negative, count);
        } else if (spec == 'u' || spec == 'x' || spec == 'X') {
            uint16_t value = (uint16_t)zx__va_uint(&args);
            char digits[5];
            char *end = digits + sizeof(digits);
            uint8_t length = zx__printf_unsigned_string(value, (spec == 'u') ? 10u : 16u,
                                                        (uint8_t)(spec == 'X'), end);
            count = zx__emit_field(end - length, length, width, left, zero, 0u, count);
        } else {
            count = zx__emit('%', count);
            if (count < 0) return -1;
            count = zx__emit(spec, count);
        }
        if (count < 0) return -1;
    }
    return count;
}
