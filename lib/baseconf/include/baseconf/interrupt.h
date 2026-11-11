#ifndef BASECONF_INTERRUPT_H
#define BASECONF_INTERRUPT_H

#include <stdint.h>
#include <baseconf.h>

/* Insert as the final instructions of an NMI handler after restoring SP/IFF2.
 * This emits OUT (0xBE),A; RETN inline; never call it as a C function. */
#define BASECONF_NMI_RETURN_ASM() __asm out(0xbeh), a __endasm __asm retn __endasm

typedef struct {
    uint16_t address;
    uint8_t enabled;
} bc_execution_trap_t;

/* Request the machine's NMI service; may transfer control immediately. */
zx_status_t bc_request_nmi(void);
/* Write the trap address and enable it for nonzero trap.enabled, or disable it
 * for zero. Even when disabling, the stored address is replaced. */
void bc_set_execution_trap(bc_execution_trap_t trap);
/* Disable the execution trap without changing its stored address; returns ZX_OK. */
zx_status_t bc_clear_execution_trap(void);

#endif
