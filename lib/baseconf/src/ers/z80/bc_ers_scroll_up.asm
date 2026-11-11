        MODULE bc_ers_scroll_up

SECTION code_clib
PUBLIC _bc_ers_scroll_up
EXTERN _bc_ers_profile

; Scrolls the supplied ERS window up, optionally moving the color attributes
; with the bitmap.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE;
; if (!window) return INVALID_ARGUMENT;
; ERS(0x49, IX=window, A=attributes);
; return OK;
;
; Caller-clean: window:16 at entry SP+2, attributes:8 at SP+4.
; Requires the ERS ROM and a window descriptor in caller RAM at 4000h..7FFFh.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_scroll_up:
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_scroll_up_unavailable
        push ix
        ld ix,0
        add ix,sp
        ld l,(ix+4)                 ; window pointer
        ld h,(ix+5)
        ld a,h
        or l
        jp z,bc_ers_scroll_up_invalid
        ld a,(ix+6)                 ; attributes
        push hl
        pop ix
        rst 08h
        defb 49h
        pop ix
        ld hl,0                     ; ZX_OK
        ret

bc_ers_scroll_up_unavailable:
        ld hl,3                     ; ZX_UNAVAILABLE
        ret

bc_ers_scroll_up_invalid:
        pop ix
        ld hl,1                     ; ZX_INVALID_ARGUMENT
        ret
