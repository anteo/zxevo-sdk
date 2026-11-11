#include <string.h>
#include <zx_test.h>

#include "../../../src/rtc/internal.h"

int main(void) {
    static const uint8_t first[] = {'A', 'V', 'R', ' ', 'F',  'I',  'R',  'M',
                                    'W', 'A', 'R', 'E', 0x21, 0x00, 0x34, 0x12};
    static const uint8_t last[] = {'A', 'V', 'R', ' ', 'B',  'O',  'O',  'T',
                                   'L', 'O', 'A', 'D', 0x9f, 0xff, 0x78, 0x56};
    zx_avr_version_t version;

    zx_test_init();
    zx__avr_decode_version(first, &version);
    ZX_ASSERT(!memcmp(version.name, first, sizeof(version.name)));
    ZX_ASSERT(version.date == 0x0021 && version.crc == 0x1234);
    ZX_ASSERT(version.year == 2000 && version.month == 1 && version.day == 1);
    ZX_ASSERT(version.official == 0);

    zx__avr_decode_version(last, &version);
    ZX_ASSERT(!memcmp(version.name, last, sizeof(version.name)));
    ZX_ASSERT(version.date == 0xff9f && version.crc == 0x5678);
    ZX_ASSERT(version.year == 2063 && version.month == 12 && version.day == 31);
    ZX_ASSERT(version.official == 1);
    zx_test_step_marker("avr-record");
    zx_test_finish();
    return 0;
}
