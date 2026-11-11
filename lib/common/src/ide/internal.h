#ifndef ZX_IDE_INTERNAL_H
#define ZX_IDE_INTERNAL_H

#include <zx/ide.h>

zx_status_t zx__ide_command(uint8_t command, uint16_t max_polls);
zx_status_t zx__ide_validate_range(uint32_t lba, const void *buffer, uint8_t count,
                                   uint16_t max_polls);

#endif
