        MODULE bc__console_control_a
EXTERN __console_w
EXTERN __console_x
EXTERN zx__console_control
SECTION code_clib
PUBLIC bc__console_control_a

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
bc__console_control_a:
        push de
        ld bc,(__console_x)
        ld de,(__console_w)
        call zx__console_control
        ld (__console_x),bc
        pop de
        ld l,0
        ret
