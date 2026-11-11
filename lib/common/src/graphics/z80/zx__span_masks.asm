        MODULE zx__span_masks
SECTION code_clib
PUBLIC zx__span_masks
EXTERN zx__edge_masks

; Return the bit masks for the first and last bytes of an inclusive ZX span.
;
; first = 0xff >> (x0 & 7); last = ~(0xff >> ((x1 & 7) + 1));
;
; A=low byte of x0, C=low byte of x1. Return B=first, C=last. AF/DE/HL
; volatile. Preserve IX/IY. A one-byte span uses first & last.
zx__span_masks:
        and 7
        ld e,a
        ld d,0
        ld hl,zx__edge_masks
        add hl,de
        ld b,(hl)
        ld a,c
        and 7
        inc a
        ld e,a
        ld hl,zx__edge_masks
        add hl,de
        ld a,(hl)
        cpl
        ld c,a
        ret
