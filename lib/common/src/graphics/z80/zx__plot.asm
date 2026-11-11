        MODULE zx__plot
SECTION code_graphics
PUBLIC zx__set
PUBLIC zx__clear
PUBLIC zx__xor
EXTERN zx__pixel_address

; Set, clear or toggle one bit in a mapped ZX bitmap. Attributes stay intact.
;
; p = screen + zx__offset(y,x >> 3);
; bit = 0x80 >> (x & 7);
; *p |= bit; /* set */
; *p &= ~bit; /* clear */
; *p ^= bit; /* xor */
;
; HL=x, DE=y in 256x192 bounds. A=high byte of a 16 KiB-aligned CPU window.
; Caller owns its writable mapping. Preserve IX/IY, clobber AF/BC/DE/HL.
zx__set:
        call zx__pixel_address
        or (hl)
        ld (hl),a
        ret

zx__clear:
        call zx__pixel_address
        cpl
        and (hl)
        ld (hl),a
        ret

zx__xor:
        call zx__pixel_address
        xor (hl)
        ld (hl),a
        ret


