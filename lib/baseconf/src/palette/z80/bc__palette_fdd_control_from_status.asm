        MODULE bc__palette_fdd_control_from_status
SECTION code_clib
PUBLIC _bc__palette_fdd_control_from_status
EXTERN bc__palette_fdd_control_from_status_regs

; SDCC status:8 at SP+2, result in L. Tail adapter.
; Preserve BC/DE/IX/IY, clobber AF/HL.
_bc__palette_fdd_control_from_status:
        ld hl,2
        add hl,sp
        ld a,(hl)
        jp bc__palette_fdd_control_from_status_regs
