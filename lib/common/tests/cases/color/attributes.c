#include <zx/color.h>
#include <zx_test.h>

int main(void) {
    zx_test_init();
    ZX_ASSERT(ZX_ATTR(COLOR_WHITE, COLOR_CYAN, 1, 1) == 0xefu);
    ZX_ASSERT(ZX_ATTR(15, 13, 1, 0) == 0x6fu);
    zx_test_finish();
    return 0;
}
