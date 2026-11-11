        MODULE bc_ers_set_palette

SECTION code_clib
PUBLIC _bc_ers_set_palette
EXTERN _bc_ers_profile

; Installs a 16-byte ATM palette in ERS firmware format.
;
; Model:
;
; if (!palette) return INVALID_ARGUMENT;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x56, A=1, HL=palette); /* 16 ERS palette bytes */
; return OK;
;
; Caller-clean: palette:16 at entry SP+2; pointer contents stay service-visible.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_set_palette:
        pop bc                      ; return address
        pop hl                      ; pointer
        push hl
        push bc
        ld a,h
        or l
        jp z,bc_ers_set_palette_invalid
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_set_palette_unavailable
        push ix
        ld a,1
        rst 08h
        defb 56h
        pop ix
        ld hl,0                     ; ZX_OK
        ret

bc_ers_set_palette_unavailable:
        ld hl,3                     ; ZX_UNAVAILABLE
        ret

bc_ers_set_palette_invalid:
        ld hl,1                     ; ZX_INVALID_ARGUMENT
        ret
