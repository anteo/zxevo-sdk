        MODULE bc_ers_cmos_init

SECTION code_clib
PUBLIC _bc_ers_cmos_init
EXTERN _bc_ers_profile

; Checks the ERS CMOS settings checksum and restores defaults when it is
; invalid.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x55, 0x00); /* verify CMOS CRC and initialize defaults if needed */
; return OK; /* firmware flags are not converted to status */
;
; No arguments; caller-clean stack.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_cmos_init:
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_cmos_init_unavailable
        push ix
        rst 08h
        defb 55h,00h
        pop ix
        ld hl,0                     ; ZX_OK
        ret

bc_ers_cmos_init_unavailable:
        ld hl,3                     ; ZX_UNAVAILABLE
        ret
