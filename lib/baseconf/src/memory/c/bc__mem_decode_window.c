#include <baseconf.h>
#include "../internal.h"
#include "../../internal.h"

void bc__mem_decode_window(uint8_t map, uint8_t window, uint8_t config_bits,
                           uint8_t substitute_bits, uint8_t protect_bits, uint8_t page_value) {
    uint8_t shift = (uint8_t)(map * 4u + window);
    bc_window_config_t *c = &bc_mem_window_cache[map][window];
    c->kind = ((config_bits >> shift) & 1u) ? BC_RAM : BC_FLASH;
    c->substitute_from_7ffd_or_dos = (uint8_t)((substitute_bits >> shift) & 1u);
    c->write_protected = (uint8_t)((protect_bits >> shift) & 1u);
    c->physical_page = (uint8_t)~page_value;
    if (c->kind == BC_FLASH) c->physical_page &= 0x1fu;
}
