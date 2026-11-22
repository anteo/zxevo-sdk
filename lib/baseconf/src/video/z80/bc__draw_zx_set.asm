        MODULE bc__draw_zx_set
EXTERN _bc_video_page0_base
EXTERN zx__set
SECTION code_graphics
PUBLIC _bc__draw_zx_set

; Set a ZX bit in the active lease's mapped screen.
; HL=x, DE=y in bounds. Clobbers AF/BC/DE/HL, preserves IX/IY.
_bc__draw_zx_set:
        ld a,(_bc_video_page0_base+1)
        jp zx__set
