        MODULE bc__console_control
SECTION code_clib
PUBLIC _bc__console_control
PUBLIC bc__console_control
EXTERN zx__console_control
EXTERN __console_x
EXTERN __console_w

; Applies a cursor-only control or ignores an unrecognized control byte.
;
; Model:
;
; if (c==LF) newline();
; else if (c==CR) cursor_x=0;
; else if (c==BS && cursor_x) --cursor_x;
; return OK;
;
; SDCC fastcall input L or native input A. Return status in L.
; The caller supplies current geometry and expands tabs through its renderer.
; No video lease is required. AF/BC/HL volatile, DE/IX/IY preserved.
_bc__console_control:
        ld a,l
bc__console_control:
        push de
        ld bc,(__console_x)
        ld de,(__console_w)
        call zx__console_control
        ld (__console_x),bc
        pop de
        ld l,0
        ret
