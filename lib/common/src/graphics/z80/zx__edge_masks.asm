        MODULE zx__edge_masks
SECTION rodata_clib
PUBLIC zx__edge_masks

; Index n keeps the rightmost 8-n bits of a ZX bitmap byte.
zx__edge_masks:
        defb 0FFh,7Fh,3Fh,1Fh,0Fh,07h,03h,01h,00h
