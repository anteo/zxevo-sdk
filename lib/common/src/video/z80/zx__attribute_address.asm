        MODULE zx__attribute_address
SECTION code_clib
PUBLIC zx__attribute_address

; Locate the ZX attribute covering a bitmap byte in the same CPU window.
;
; return (bitmap & 0xc0ff) | 0x1800 | ((bitmap & 0x1800) >> 3);
;
; HL=bitmap byte within the first 1800h bytes of a 16 KiB-aligned window.
; Return DE=attribute address. AF/DE volatile, BC/HL/IX/IY preserved.
zx__attribute_address:
        ; Keep the cell row within the third and the byte column in L.
        ; Move the bitmap third from H bits 4:3 to attribute bits 1:0.
        ld a,h
        and 18h
        rrca
        rrca
        rrca
        or 18h
        ld d,a
        ld a,h
        and 0c0h
        or d
        ld d,a
        ld e,l
        ret
