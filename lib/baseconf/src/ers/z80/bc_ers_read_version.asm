        MODULE bc_ers_read_version

SECTION code_clib
PUBLIC _bc_ers_read_version
EXTERN _bc_ers_profile

; Reads the ERS version and copies the firmware's version and feature bytes
; verbatim.
;
; Model:
;
; if (!version) return INVALID_ARGUMENT; if (profile == NONE) return UNAVAILABLE;
; ERS(0x4d); *version = {B, C, D, E, A}; return OK;
;
; Entry SP+2 = version pointer. Result capture IX: DE +0, BC +2, AF +4,
; version pointer +6, saved IX +8. The fifth output byte is A, not CPU F.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_read_version:
        pop bc                      ; return address
        pop hl                      ; output pointer
        push hl
        push bc
        ld a,h
        or l
        jp z,bc_ers_read_version_invalid
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_read_version_unavailable

        push ix
        push hl
        rst 08h
        defb 4dh
        push af
        push bc
        push de
        ld ix,0
        add ix,sp
        ld l,(ix+6)
        ld h,(ix+7)
        ld a,(ix+3)                 ; B
        ld (hl),a
        inc hl
        ld a,(ix+2)                 ; C
        ld (hl),a
        inc hl
        ld a,(ix+1)                 ; D
        ld (hl),a
        inc hl
        ld a,(ix+0)                 ; E
        ld (hl),a
        inc hl
        ld a,(ix+5)                 ; A flags
        ld (hl),a
        pop de
        pop bc
        pop af
        pop hl
        pop ix
        ld hl,0                     ; ZX_OK
        ret

bc_ers_read_version_invalid:
        ld hl,1
        ret
bc_ers_read_version_unavailable:
        ld hl,3
        ret
