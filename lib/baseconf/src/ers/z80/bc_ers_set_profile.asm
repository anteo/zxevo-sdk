        MODULE bc_ers_set_profile

SECTION code_clib
PUBLIC _bc_ers_set_profile
EXTERN _bc_ers_profile

; Store the low byte of the caller-clean SP+2 profile slot; no probing.
; No result. AF/BC/HL clobbered; DE/IX/IY preserved.
_bc_ers_set_profile:
        pop bc                      ; return address
        pop hl                      ; profile
        push hl
        push bc
        ld a,l
        ld (_bc_ers_profile),a
        ret
