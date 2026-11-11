        MODULE bc__mem_xx77_port
SECTION code_clib
PUBLIC _bc__mem_xx77_port
EXTERN bc__video_system_port_for_regs

; Reconstruct xx77 without changing its palette gate. Fastcall L = 0Ch
; readback byte, HL = port. Preserve DE/IX/IY, clobber AF/BC/HL.
_bc__mem_xx77_port:
        ld a,l
        ld c,0
        jp bc__video_system_port_for_regs
