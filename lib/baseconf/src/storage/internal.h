#ifndef BASECONF_STORAGE_INTERNAL_H
#define BASECONF_STORAGE_INTERNAL_H

#include <baseconf.h>
#include <baseconf/storage.h>
#include "../internal.h"

uint16_t bc__storage_fdd_system_port(uint8_t config, uint8_t force_palette_closed);
zx_status_t bc__storage_fdd_shadow_begin(uint8_t *irq, uint8_t *bf);
void bc__storage_fdd_shadow_end(uint8_t irq, uint8_t bf);

#endif
