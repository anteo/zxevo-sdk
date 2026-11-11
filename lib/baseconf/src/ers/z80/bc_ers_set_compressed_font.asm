        MODULE bc_ers_set_compressed_font

SECTION code_clib
PUBLIC _bc_ers_set_compressed_font
EXTERN _bc_ers_profile

; Installs a built-in ERS font or a caller-supplied compressed font.
;
; Model:
;
; if (kind > 2 || !data) return INVALID_ARGUMENT;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x57, A=kind, HL=data); return OK;
;
; IX frame used here: one-byte kind +4, data pointer +5. Kind 2 supplies compressed
; ERS font data; NULL is rejected even when a built-in kind ignores the pointer.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_set_compressed_font:
        push ix
        ld ix,0
        add ix,sp
        ld a,(ix+4)
        cp 3
        jp nc,bc_ers_set_compressed_font_invalid
        ld l,(ix+5)
        ld h,(ix+6)
        ld a,h
        or l
        jp z,bc_ers_set_compressed_font_invalid
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_set_compressed_font_unavailable
        ld a,(ix+4)
        rst 08h
        defb 57h
        pop ix
        ld hl,0
        ret
bc_ers_set_compressed_font_invalid:
        pop ix
        ld hl,1
        ret
bc_ers_set_compressed_font_unavailable:
        pop ix
        ld hl,3
        ret
