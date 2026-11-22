        MODULE zx_ide_wait_data
EXTERN zx__ide_wait_regs
SECTION code_clib
PUBLIC _zx_ide_wait_data

; Poll ATA status for the data-request phase, returning status in L.
_zx_ide_wait_data:
        ld de,0808h
        jp zx__ide_wait_regs
