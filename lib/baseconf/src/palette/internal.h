#ifndef BASECONF_PALETTE_INTERNAL_H
#define BASECONF_PALETTE_INTERNAL_H

#include <baseconf/palette.h>

extern bc_rgb444_t bc_palette_rgb444_cache[16];
extern uint8_t bc_palette_rgb444_valid[16];

uint8_t bc__palette_encode_rgb222(bc_rgb222_t color);
uint8_t bc__palette_fdd_control_from_status(uint8_t status);
void bc__palette_restore_atm_ports(uint8_t config, uint8_t fdd_control);

#endif
