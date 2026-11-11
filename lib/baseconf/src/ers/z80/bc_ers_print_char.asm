        MODULE bc_ers_print_char

SECTION code_clib
PUBLIC _bc_ers_print_char
EXTERN _bc_ers_profile

; Prints one character in the current ERS window.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x48, A=character);
; return OK;
;
; Caller-clean: character is read from the low byte of the entry SP+2 slot.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_print_char:
        pop bc                      ; return address
        pop hl                      ; argument
        push hl
        push bc
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_print_char_unavailable
        ld a,l
        push ix
        rst 08h
        defb 48h
        pop ix
        ld hl,0                     ; ZX_OK
        ret

bc_ers_print_char_unavailable:
        ld hl,3                     ; ZX_UNAVAILABLE
        ret
