#include <baseconf.h>
#include "../internal.h"

bc_readback_backend_t bc_get_readback_backend(void) {
    return bc_mem_readback_backend;
}
