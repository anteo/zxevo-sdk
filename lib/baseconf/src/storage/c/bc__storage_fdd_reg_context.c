#include "../internal.h"

zx_status_t bc__storage_fdd_reg_context(void) {
    /* FE interception swallows WD1793 accesses when its other conditions hold;
     * the library cannot safely infer ROM/DOS/window state from 13BD alone. */
    return (z80_inp(0x13bdu) & 0x0fu) ? ZX_UNSAFE_CONTEXT : ZX_OK;
}
