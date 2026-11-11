        MODULE zx_draw_line_op
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _zx_draw_line_op
PUBLIC zx__graphics_line_op_a
EXTERN _bc__graphics_begin
EXTERN bc__graphics_prepare_line_a
EXTERN _bc__video_end

; Draw a segment through the native line loop under a graphics lease.
; Also serves classic diagonals without depending on the axis span engines.
;
; if (!graphics_begin()) return;
; prepare_line(x0,y0,x1,y1,op);
; video_end();
;
; SDCC four words followed by a byte. The shorthand entry takes op in A
; instead. Preserve IX/IY, clobber AF/BC/DE/HL. One temporary word saves
; the operation across begin. The four endpoint words are forwarded to prep.
_zx_draw_line_op:
        ld hl,10
        add hl,sp
        ld a,(hl)
zx__graphics_line_op_a:
        push af
        call _bc__graphics_begin
        pop bc
        ret z

        BC_ABI_PUSH_WORDS_REVERSE 4,2
        ld a,b
        call bc__graphics_prepare_line_a
        BC_ABI_DROP_WORDS 4
        jp _bc__video_end
