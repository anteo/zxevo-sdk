        MODULE zx__clear
EXTERN zx__pixel_address
SECTION code_graphics
PUBLIC zx__clear

zx__clear:
        call zx__pixel_address
        cpl
        and (hl)
        ld (hl),a
        ret
