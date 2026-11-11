        MODULE bc_ers_is_available

SECTION code_clib
PUBLIC _bc_ers_is_available
EXTERN _bc_ers_profile

; Return HL = (profile != NONE), with no firmware call or hardware probe.
; No arguments; AF/HL clobbered, BC/DE/IX/IY preserved.
_bc_ers_is_available:
        ld a,(_bc_ers_profile)
        or a
        ld hl,0
        ret z
        inc l
        ret
