        MODULE bc_ers_printer_write

SECTION code_clib
PUBLIC _bc_ers_printer_write
EXTERN _bc_ers_profile

; Sends one printable character through the BASIC AY printer hook.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x41, A=character);
; return OK;
;
; Caller-clean: character is read from the low byte of the entry SP+2 slot.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_printer_write:
        pop bc                      ; return address
        pop hl                      ; argument
        push hl
        push bc
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_printer_write_unavailable
        ld a,l
        push ix
        rst 08h
        defb 41h
        pop ix
        ld hl,0                     ; ZX_OK
        ret

bc_ers_printer_write_unavailable:
        ld hl,3                     ; ZX_UNAVAILABLE
        ret
