        MODULE zx_ide_wait_complete
EXTERN zx__ide_wait_regs
SECTION code_clib
PUBLIC _zx_ide_wait_complete
_zx_ide_wait_complete:
        ld de,0008h
        call zx__ide_wait_regs
        ld a,l
        or a
        ret nz
        ld c,0F0h
        in a,(c)
        ret
