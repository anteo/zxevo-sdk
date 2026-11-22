        MODULE zx__ide_wait_bus
EXTERN zx__ide_wait_regs
SECTION code_clib
PUBLIC zx__ide_wait_bus
zx__ide_wait_bus:
        ld de,8008h                  ; D.7 selects the pre-selection phase
        jp zx__ide_wait_regs
