        MODULE bc_ers_set_mode

SECTION code_clib
PUBLIC _bc_ers_set_mode
EXTERN _bc_ers_profile

; Queries the saved ERS mode bits or requests a firmware video, turbo or
; memory setting change.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE; if (!saved_mode) return INVALID_ARGUMENT;
; ERS(0x4b, A=request); *saved_mode = A; return OK;
;
; IX frame used here: one-byte request +4, saved_mode pointer +5. Request zero queries
; saved firmware settings; output A is only defined for that query.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_set_mode:
        push ix
        ld ix,0
        add ix,sp
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_set_mode_unavailable
        ld e,(ix+5)
        ld d,(ix+6)
        ld a,d
        or e
        jp z,bc_ers_set_mode_invalid
        ld a,(ix+4)
        rst 08h
        defb 4bh
        ld e,(ix+5)
        ld d,(ix+6)
        ld (de),a
        pop ix
        ld hl,0
        ret
bc_ers_set_mode_invalid:
        pop ix
        ld hl,1
        ret
bc_ers_set_mode_unavailable:
        pop ix
        ld hl,3
        ret
