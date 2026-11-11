        MODULE bc__graphics_select_writer
SECTION code_graphics
PUBLIC bc__graphics_select_writer
EXTERN bc__draw_select_regs
EXTERN _bc_draw_callback

; Select and publish a native pixel writer. A=in_bounds, B=operation.
; Z means no writer. Preserve IX/IY, clobber AF/BC/DE/HL.
bc__graphics_select_writer:
        call bc__draw_select_regs
        ld (_bc_draw_callback),hl
        ret
