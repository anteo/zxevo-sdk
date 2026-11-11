#ifndef ZX_AUDIO_H
#define ZX_AUDIO_H

#include <stdint.h>
#include <zx/status.h>

/* Play length bytes of packed 4-bit samples through Covox port 00FBh, high
 * nibble first (two samples per byte). Blocks until all bytes are played.
 * Timing depends on CPU speed and interrupts; this call does not change either.
 * Returns ZX_INVALID_ARGUMENT for NULL samples or zero length, otherwise ZX_OK. */
zx_status_t zx_covox_play(const uint8_t *samples, uint16_t length);

/* Initialize the z88dk Vortex Tracker II player and leave playback disabled.
 * module must point to valid PT3 data that stays CPU-accessible during playback.
 * Returns ZX_INVALID_ARGUMENT for NULL module; the module format is not checked. */
zx_status_t zx_pt3_init(const void *module);
/* Mute the current AY output without disabling playback ticks. */
void zx_pt3_mute(void);
/* Advance playback by one tick if started; otherwise do nothing.
 * Call at the module's intended frame rate; no interrupt handler is installed. */
void zx_pt3_play(void);
/* Enable subsequent zx_pt3_play calls; initialize the player first.
 * Resumes the current position without restarting the module. */
void zx_pt3_start(void);
/* Disable subsequent playback ticks and mute AY; keeps the current position. */
void zx_pt3_stop(void);

#endif
