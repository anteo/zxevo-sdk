#include <zx/printf.h>

int zx_console_printf(const char *format, ...) {
    va_list args;
    int count;
    va_start(args, format);
    count = zx_console_vprintf(format, args);
    va_end(args);
    return count;
}
