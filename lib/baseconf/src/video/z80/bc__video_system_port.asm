        MODULE bc__video_system_port
SECTION code_clib
PUBLIC _bc__video_system_port
INCLUDE "memory/readback.inc"
EXTERN bc__video_system_port_for_regs

; Read the live system configuration and derive its xx77 address. Model:
;
; return system_port_for(readback(0x0c), palette_allowed);
;
; SDCC palette_allowed:8 at SP+2, result in HL. Preserve DE/IX/IY,
; clobber AF/BC/HL. Readback uses the configured BD/BE backend.
_bc__video_system_port:
        BC_MEM_READBACK 0Ch, a
        ld hl,2
        add hl,sp
        ld c,(hl)
        jp bc__video_system_port_for_regs
