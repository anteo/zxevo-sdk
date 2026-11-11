        MODULE bc_ers_draw_window

SECTION code_clib
PUBLIC _bc_ers_draw_window
EXTERN _bc_ers_profile

; Draws or selects an ERS window from a firmware-format descriptor.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE;
; if (!window) return INVALID_ARGUMENT;
; ERS(0x46, IX=window); /* bc_ers_window_t is the native 20-byte descriptor */
; return OK;
;
; Caller-clean: window pointer at entry SP+2; contents stay service-visible.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_draw_window:
        pop bc                      ; return address
        pop hl                      ; pointer
        push hl
        push bc
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_draw_window_unavailable
        ld a,h
        or l
        jp z,bc_ers_draw_window_invalid
        push ix
        push hl
        pop ix
        rst 08h
        defb 46h
        pop ix
        ld hl,0                     ; ZX_OK
        ret

bc_ers_draw_window_unavailable:
        ld hl,3                     ; ZX_UNAVAILABLE
        ret

bc_ers_draw_window_invalid:
        ld hl,1                     ; ZX_INVALID_ARGUMENT
        ret
