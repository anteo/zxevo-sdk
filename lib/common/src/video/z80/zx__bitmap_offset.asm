        MODULE zx__bitmap_offset
SECTION code_clib
PUBLIC zx__bitmap_offset

; C=pixel y, E=byte column, D=optional aligned window high byte.
;
; Converts a scanline and byte column into an offset in the interleaved ZX
; bitmap.
;
; Model:
;
; return base | ((y&7)<<8) | ((y&0xc0)<<5) | ((y&0x38)<<2) | x_byte;
;
; For screen access y is 0..191 and x_byte 0..31; helper itself does no checks.
; Return HL. AF/HL volatile, BC/DE/IX/IY preserved.
zx__bitmap_offset:
        ld a,c
        and 7
        ld h,a
        ld a,c
        and 0C0h
        rrca
        rrca
        rrca
        or h
        or d
        ld h,a
        ld a,c
        and 38h
        add a,a
        add a,a
        or e
        ld l,a
        ret
