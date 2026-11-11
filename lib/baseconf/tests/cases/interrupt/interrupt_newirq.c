#include <baseconf.h>

#include "bc_case.h"

int main(void) {
    bc_newirq_status_t status = {0xa5, 0x5a};
    if (bc_case_init() == ZX_OK) {
        ZX_ASSERT(bc_newirq_status(0) == ZX_INVALID_ARGUMENT);
        ZX_ASSERT(bc_newirq_status(&status) == ZX_UNAVAILABLE);
        ZX_ASSERT(status.pending == 0xa5 && status.source == 0x5a);
        ZX_ASSERT(bc_newirq_enable_sources(1) == ZX_UNAVAILABLE);
        ZX_ASSERT(bc_newirq_acknowledge(1) == ZX_UNAVAILABLE);
        zx_test_step_marker("disabled");
        zx_test_step_skip("sources", "ZEsarUX has no BaseConf newirq registers");
    }
    zx_test_finish();
    return 0;
}
