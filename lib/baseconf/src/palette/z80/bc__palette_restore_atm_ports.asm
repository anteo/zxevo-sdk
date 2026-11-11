        MODULE bc__palette_restore_atm_ports
SECTION code_clib
PUBLIC _bc__palette_restore_atm_ports
EXTERN bc__palette_restore_atm_ports_regs

; SDCC config:8 at SP+2, fdd_control:8 at SP+3, void result.
; Tail adapter. Preserve IX/IY, clobber AF/BC/DE/HL.
_bc__palette_restore_atm_ports:
        ld hl,2
        add hl,sp
        ld e,(hl)                    ; saved config
        inc hl
        ld d,(hl)                    ; saved FDD control
        jp bc__palette_restore_atm_ports_regs
