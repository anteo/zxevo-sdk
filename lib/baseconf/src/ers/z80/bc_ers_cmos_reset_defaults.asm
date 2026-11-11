        MODULE bc_ers_cmos_reset_defaults

SECTION code_clib
PUBLIC _bc_ers_cmos_reset_defaults
EXTERN _bc_ers_profile

; Asks ERS to replace its CMOS settings with firmware defaults.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x55, 0x03); /* reset CMOS defaults */
; return OK; /* firmware flags are not converted to status */
;
; No arguments; caller-clean stack.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_cmos_reset_defaults:
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_cmos_reset_defaults_unavailable
        push ix
        rst 08h
        defb 55h,03h
        pop ix
        ld hl,0                     ; ZX_OK
        ret

bc_ers_cmos_reset_defaults_unavailable:
        ld hl,3                     ; ZX_UNAVAILABLE
        ret
