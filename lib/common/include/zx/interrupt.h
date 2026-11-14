#ifndef ZX_INTERRUPT_H
#define ZX_INTERRUPT_H

#include <stdint.h>
#include <zx/status.h>

/* Execute EI for nonzero enabled or DI for zero; does not affect NMI. */
void zx_interrupt_enable(uint8_t enabled);
/* Disable INT and return its previous state as 0 or 1 (sampled from IFF2).
 * Do not use from NMI to infer the current IFF1 state. */
uint8_t zx_interrupt_save_disable(void);
/* Re-enable INT if the saved state is nonzero; zero does nothing. Pair with
 * zx_interrupt_save_disable while INT is still disabled. This does not execute
 * DI for zero, so it cannot restore a disabled state after an intervening EI. */
void zx_interrupt_restore(uint8_t enabled) __z88dk_fastcall;
/* Wait in HALT for an interrupt to wake the CPU. Returns ZX_UNSAFE_CONTEXT
 * if maskable interrupts are disabled, or ZX_OK after wakeup. NMI can also
 * wake HALT. This call leaves the interrupt-enable state alone and must be
 * called outside interrupt handlers. For frame pacing, ensure frame INT is
 * the only possible waking source. */
zx_status_t zx_wait_interrupt(void);

/* Wait for a change to a resident byte incremented by the frame ISR.
 * Other IRQs and NMI may wake the CPU, but the wait continues until the
 * counter changes. Call outside interrupt handlers with maskable interrupts
 * enabled and a running frame source. The ISR must preserve the interrupted
 * registers. Returns ZX_INVALID_ARGUMENT for NULL or ZX_UNSAFE_CONTEXT
 * when maskable interrupts are disabled. */
zx_status_t zx_wait_frame(const volatile uint8_t *frame_counter) __z88dk_fastcall;

/* Wait for count successive frame interrupts using the same resident counter
 * and preconditions as zx_wait_frame(). Zero count returns ZX_OK immediately.
 * Return the first wait error or ZX_OK after the final frame. */
zx_status_t zx_wait_frames(const volatile uint8_t *frame_counter, uint16_t count);

/* Fastcall ABI adapter for classic z88dk im2_Init (whose header omits its
 * register calling convention). Use im2.h for ISR creation/registration.
 * Table is 256-byte aligned, 257 resident bytes; call with IRQ disabled.
 * This selects IM2 and leaves IFF unchanged; it does not populate the table. */
void im2_Init_fastcall(void *table) __z88dk_fastcall;

#endif
