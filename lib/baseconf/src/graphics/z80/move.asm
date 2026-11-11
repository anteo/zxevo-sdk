        MODULE move
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _move
EXTERN bc__graphics_draw_to
EXTERN _bc_graphics_x
EXTERN _bc_graphics_y

; Convert Small-C dx,dy to the new cursor position and tail-enter drawing.
; Caller cleans its arguments. Preserve IX/IY.
_move:
        BC_ABI_LOAD_SMALLC_PAIR
        ld bc,(_bc_graphics_x)
        add hl,bc
        ex de,hl
        ld bc,(_bc_graphics_y)
        add hl,bc
        ex de,hl
        xor a
        jp bc__graphics_draw_to
