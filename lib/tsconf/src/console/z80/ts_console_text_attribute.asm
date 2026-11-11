        MODULE ts_console_text_attribute
SECTION code_clib
PUBLIC ts_console_text_attribute
EXTERN zx__ink
EXTERN zx__paper

; Pack the current colors into the native text attribute, paper in bits 7:4
; and ink in bits 3:0. Return A, clobber AF/E, preserve BC/D/HL/IX/IY.
ts_console_text_attribute:
        ld a,(zx__paper)
        rlca
        rlca
        rlca
        rlca
        and 0f0h
        ld e,a
        ld a,(zx__ink)
        and 0fh
        or e
        ret
