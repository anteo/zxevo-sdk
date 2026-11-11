        MODULE bc__line_loop
SECTION code_graphics
PUBLIC _bc__line_loop
EXTERN zx__line_run
EXTERN _bc_draw_callback

; Enter the common Bresenham loop with the writer selected for the lease.
; SDCC endpoints on the stack. Preserves IX/IY, clobbers AF/BC/DE/HL.
_bc__line_loop:
        ld hl,(_bc_draw_callback)
        jp zx__line_run
