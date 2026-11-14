#ifndef ZX_AUDIO_H
#define ZX_AUDIO_H

#include <stdint.h>
#include <zx/status.h>
#include <zx/memory.h>

typedef enum { ZX_AY_CHIP_0 = 0, ZX_AY_CHIP_1 = 1 } zx_ay_chip_t;

/* Select the first (CHIP_0) or second (CHIP_1) AY of TurboSound for subsequent
 * AY register accesses, including PT3 and AYFX output. Selection persists;
 * this call does not mute/reset either chip or restore the previous selection.
 * Returns ZX_OK for a valid chip, ZX_INVALID_ARGUMENT without writing ports
 * otherwise. TurboSound support must be known by the caller: this is not a
 * hardware probe and ZX_OK does not confirm that a second chip is present.
 * IFF is unchanged. Serialize selection AND the following AY accesses with
 * IRQ/NMI users, or have the ISR restore the chip expected by interrupted code.
 * PT3 and AYFX each retain one shared player state, not one state per chip. */
zx_status_t zx_ay_select_chip(zx_ay_chip_t chip) __z88dk_fastcall;

/* Play length unsigned PCM8 samples through port 00FBh, then output 128.
 * Blocks; CPU clock and IFF are unchanged. Samples remain mapped/readable and
 * must not wrap the CPU address space. Delay must be 1..255; sample spacing is
 * 64+14*delay T-states, excluding interrupts/waits. At 3.5 MHz delay=18 gives
 * 11076 Hz. Returns ZX_INVALID_ARGUMENT for NULL, zero length or zero delay. */
zx_status_t zx_covox_play(const uint8_t *samples, uint16_t length, uint8_t delay);

/* Write one unsigned PCM8 level to the Covox DAC at port 00FBh. Value 128
 * is the idle midpoint. Does not change CPU speed or interrupt state. */
void zx_covox_set_level(uint8_t level);

typedef struct {
    zx_ram_page_t first_page;
    uint16_t offset;
    uint16_t length;
    uint8_t delay;
} zx_pcm8_banked_t;

/* Play unsigned PCM8 through port 00FBh from consecutive physical RAM pages.
 * The caller selects W0..W3 and owns a resident lease until playback returns;
 * TSConf can lease W2/W3, BaseConf any unpinned window. The descriptor, code,
 * stack and lease must stay outside the selected window. Requires offset <
 * 16384, nonzero length/delay and no page-number wrap. INT is saved/disabled
 * during playback and restored afterward. CPU speed and cache are unchanged:
 * the caller sets them for the required sample rate. Each normal sample gap
 * is 64+14*delay T-states; bank changes add a short gap. Returns the DAC to
 * 128 at the end. If release fails, the lease stays active for caller retry. */
zx_status_t zx_pcm8_play_banked(const zx_pcm8_banked_t *sample, zx_window_t window,
                                zx_ram_lease_t *lease);

/* Initialize the z88dk Vortex Tracker II player and leave playback disabled.
 * PT3 output uses the currently selected AY; no TurboSound chip is selected
 * automatically. On TurboSound select the intended chip with zx_ay_select_chip.
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

/* Initialize a valid AYFX Editor AFB bank and silence the selected AY.
 * The bank and its effect streams must remain CPU-accessible for play/frame.
 * Returns ZX_INVALID_ARGUMENT for NULL or a zero-effect bank, else ZX_OK.
 * Data is trusted: stream bounds and the AFB offset table are not validated.
 * Select a TurboSound chip with zx_ay_select_chip before output when needed.
 * These routines do not select a TurboSound chip or install an ISR. Serialize
 * init/stop with frame (for example, by saving/disabling interrupts). */
zx_status_t zx_ayfx_init(const void *bank) __z88dk_fastcall;
/* Start on a free channel or replace the oldest of three active effects.
 * volume is an additive adjustment in -15..15; output clips to 0..15.
 * Returns ZX_NOT_INITIALIZED before init, ZX_INVALID_ARGUMENT for an invalid
 * index/volume, otherwise ZX_OK. Does not output registers until frame.
 * Saves/disables INT around channel-state changes and restores the prior IFF. */
zx_status_t zx_ayfx_play(uint8_t effect, int8_t volume);
/* Advance effects by one tick and overlay their channels on the selected AY.
 * For shared-chip music call PT3 first, then AYFX, at the intended frame rate.
 * Inactive channels are untouched. An ending effect silences its channel for
 * this tick; subsequent music ticks can restore it. AY noise is chip-global.
 * IX/IY are preserved; no quiet-effect suppression or envelope is applied. */
void zx_ayfx_frame(void);
/* Stop all effects and silence all three channels of the selected AY.
 * Keeps the bank initialized; preserves the mixer's I/O direction bits. */
void zx_ayfx_stop(void);

#endif
