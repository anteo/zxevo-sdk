        MODULE bc_ers_print_message

SECTION code_clib
PUBLIC _bc_ers_print_message
EXTERN _bc_ers_profile

; Prints a null-terminated control string in the current ERS window.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE;
; if (!window || !message) return INVALID_ARGUMENT;
; ERS(0x47, IX=window, HL=message);
; return OK;
;
; Caller-clean: window:16 at SP+2, message:16 at SP+4.
; Requires the ERS ROM and a window descriptor in caller RAM at 4000h..7FFFh.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_print_message:
        pop bc                      ; return address
        pop de                      ; window
        pop hl                      ; message
        push hl
        push de
        push bc
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_print_message_unavailable
        ld a,d
        or e
        jp z,bc_ers_print_message_invalid
        ld a,h
        or l
        jp z,bc_ers_print_message_invalid
        push ix
        push de
        pop ix
        rst 08h
        defb 47h
        pop ix
        ld hl,0                     ; ZX_OK
        ret

bc_ers_print_message_unavailable:
        ld hl,3                     ; ZX_UNAVAILABLE
        ret

bc_ers_print_message_invalid:
        ld hl,1                     ; ZX_INVALID_ARGUMENT
        ret
