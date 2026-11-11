        MODULE bc__graphics_draw_to
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC bc__graphics_draw_to
EXTERN _bc_graphics_x
EXTERN _bc_graphics_y
EXTERN _bc_graphics_pen_down
EXTERN _bc__graphics_draw_line

; Move to the new cursor position, drawing the requested line if applicable.
;
; if (op != SET || pen_down) draw_line(graphics_x,graphics_y,x,y,op);
; graphics_x = x; graphics_y = y;
;
; HL=x, DE=y, A=operation. Preserve IX/IY, clobber AF/BC/DE/HL. Save the
; new cursor below the outgoing line arguments until the line call returns.
bc__graphics_draw_to:
        or a
        jr nz,@draw
        ld a,(_bc_graphics_pen_down)
        or a
        jr z,@store
        xor a
@draw:
        push hl
        push de
        BC_ABI_PUSH_BYTE
        push de
        push hl
        ld hl,(_bc_graphics_y)
        push hl
        ld hl,(_bc_graphics_x)
        push hl
        call _bc__graphics_draw_line
        BC_ABI_DROP_WORDS 4
        inc sp
        pop de
        pop hl
@store:
        ld (_bc_graphics_x),hl
        ld (_bc_graphics_y),de
        ret
