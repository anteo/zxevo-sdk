        MODULE zx__ide_wait_idle
EXTERN zx__ide_wait_regs
SECTION code_clib
PUBLIC zx__ide_wait_idle
zx__ide_wait_idle:
        ld de,4048h
        jp zx__ide_wait_regs
