        MODULE bc__draw_zx_xor
EXTERN _bc_video_page0_base
EXTERN zx__xor
SECTION code_graphics
PUBLIC _bc__draw_zx_xor

; Xor a ZX bit in the active lease's mapped screen.
; HL=x, DE=y in bounds. Clobbers AF/BC/DE/HL, preserves IX/IY.
_bc__draw_zx_xor:
        ld a,(_bc_video_page0_base+1)
        jp zx__xor
