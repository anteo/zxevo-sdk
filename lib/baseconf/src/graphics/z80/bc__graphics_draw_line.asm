        MODULE bc__graphics_draw_line
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _bc__graphics_draw_line
EXTERN _bc__graphics_begin
EXTERN _bc__video_hline
EXTERN _bc__video_vline
EXTERN zx__graphics_line_op_a
EXTERN _bc__video_end

defc BC_DRAW_LINE_X0 = 4
defc BC_DRAW_LINE_Y0 = 6
defc BC_DRAW_LINE_X1 = 8
defc BC_DRAW_LINE_Y1 = 10
defc BC_DRAW_LINE_OPERATION = 12

; Dispatch classic lines to the axis span engines or to the direct
; API's Bresenham entry.
;
; if (y0 != y1 && x0 != x1) return line_op(x0,y0,x1,y1,op);
; if (!graphics_begin()) return;
; if (y0 == y1) video_hline(x0,x1,y0,op); else video_vline(x0,y0,y1,op);
; video_end();
;
; SDCC four coordinate words and an operation byte. IX points at saved IX
; while dispatching. Outgoing words are separate copies because the axis
; engines normalize their arguments in place. The diagonal tail call reuses
; the original argument words and acquires its own lease. Preserve IX/IY,
; clobber AF/BC/DE/HL. Save the axis selector across the axis lease setup.
_bc__graphics_draw_line:
        push ix
        ld ix,0
        add ix,sp

        ld a,(ix+BC_DRAW_LINE_Y0)
        cp (ix+BC_DRAW_LINE_Y1)
        jr nz,@check_x
        ld a,(ix+BC_DRAW_LINE_Y0+1)
        cp (ix+BC_DRAW_LINE_Y1+1)
        jr z,@horizontal
@check_x:
        ld a,(ix+BC_DRAW_LINE_X0)
        cp (ix+BC_DRAW_LINE_X1)
        jr nz,@diagonal
        ld a,(ix+BC_DRAW_LINE_X0+1)
        cp (ix+BC_DRAW_LINE_X1+1)
        jr z,@vertical

@diagonal:
        ld a,(ix+BC_DRAW_LINE_OPERATION)
        pop ix
        jp zx__graphics_line_op_a

@horizontal:
        xor a
        jr @axis
@vertical:
        ld a,1
@axis:
        push af
        call _bc__graphics_begin
        pop bc
        jr z,@return
        ld a,b
        or a
        ld a,(ix+BC_DRAW_LINE_OPERATION)
        BC_ABI_PUSH_BYTE
        jr nz,@vertical_args
        BC_ABI_PUSH_IX_WORD BC_DRAW_LINE_Y0
        BC_ABI_PUSH_IX_WORD BC_DRAW_LINE_X1
        BC_ABI_PUSH_IX_WORD BC_DRAW_LINE_X0
        call _bc__video_hline
        jr @drop_axis

@vertical_args:
        BC_ABI_PUSH_IX_WORD BC_DRAW_LINE_Y1
        BC_ABI_PUSH_IX_WORD BC_DRAW_LINE_Y0
        BC_ABI_PUSH_IX_WORD BC_DRAW_LINE_X0
        call _bc__video_vline
@drop_axis:
        BC_ABI_DROP_WORDS 3
        inc sp
        pop ix
        jp _bc__video_end
@return:
        pop ix
        ret
