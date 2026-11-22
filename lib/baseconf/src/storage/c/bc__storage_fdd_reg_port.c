#include "../internal.h"

uint16_t bc__storage_fdd_reg_port(zx_fdd_reg_t reg) {
    static const uint8_t ports[] = {0x1f, 0x3f, 0x5f, 0x7f};
    return (uint16_t)ports[(uint8_t)reg];
}
