        MODULE zx__xor
EXTERN zx__pixel_address
SECTION code_graphics
PUBLIC zx__xor

zx__xor:
        call zx__pixel_address
        xor (hl)
        ld (hl),a
        ret
