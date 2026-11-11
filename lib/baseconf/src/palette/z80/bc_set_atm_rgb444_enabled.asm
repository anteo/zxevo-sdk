        MODULE bc_set_atm_rgb444_enabled
SECTION code_clib
PUBLIC _bc_set_atm_rgb444_enabled
EXTERN _zx_interrupt_save_disable
EXTERN _zx_interrupt_restore

; Update only BF.5 with INT masked. Caller excludes NMI.
; SDCC fastcall L = enable; preserve IX/IY, clobber AF/BC/DE/HL.
_bc_set_atm_rgb444_enabled:
        push hl
        call _zx_interrupt_save_disable
        pop de
        ld bc,00BFh
        in a,(c)
        res 5,a
        inc e
        dec e
        jr z,@write
        set 5,a
@write:
        out (c),a
        jp _zx_interrupt_restore
