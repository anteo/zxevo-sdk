#ifndef ZX_PRIVATE_PCM8_H
#define ZX_PRIVATE_PCM8_H
#include <stdint.h>
/* Trusted nonzero length/delay, no trailing idle output. */
void zx__covox_pcm8_block(const uint8_t *samples, uint16_t length, uint8_t delay);
#endif
