        MODULE zx_draw_ellipse_op
SECTION code_graphics
PUBLIC _zx_draw_ellipse_op
PUBLIC zx__graphics_ellipse_op_a
IFDEF TSCONF_VIDEO_BITMAP
INCLUDE "graphics/z80/zx__ellipse.inc"
EXTERN zx__ellipse_endpoints
EXTERN zx__ellipse_walk
EXTERN zx__line_clip
EXTERN ts__graphics_begin_writer
EXTERN ts__graphics_end_writer

; Draw a clipped ellipse, with a line for either zero semi-axis.
;
; if (rx > 511 || ry > 511 || center_cannot_reach_canvas) return;
; writer = begin_writer(operation);
; if (writer) {
;     endpoints = {cx-rx, cy-ry, cx+rx, cy+ry};
;     if (!rx || !ry) line_clip(endpoints, width, height, writer);
;     else ellipse_walk(endpoints, cx, cy, rx, ry, writer);
;     end_writer();
; }
;
; SDCC cx/cy/rx/ry words at SP+2/+4/+6/+8 and operation at SP+10.
; The shorthand entry takes the operation in A.
; IX anchors the shared ellipse frame after saving IX/IY. Its DX and DY
; slots hold clipping dimensions until the ellipse walk or line call.
; IY carries the selected pixel writer. Preserve caller IX/IY.
_zx_draw_ellipse_op:
        ld hl,10
        add hl,sp
        ld a,(hl)
zx__graphics_ellipse_op_a:
        ld b,a
        push ix
        ld ix,0
        add ix,sp
        ld a,(ix+9)
        or (ix+11)
        cp 2
        jp nc,@reject
        ; Centers outside [-512,1023] cannot reach a canvas with these radii.
        ld a,(ix+5)
        call @center_range
        jp c,@reject
        ld a,(ix+7)
        call @center_range
        jp c,@reject
        ld a,b
        call ts__graphics_begin_writer
        jp c,@reject
        push iy
        push hl
        pop iy
        ld hl,-ZX_ELLIPSE_FRAME
        add hl,sp
        ld sp,hl
        push hl
        pop ix
        ld (ix+ZX_ELLIPSE_DX),c
        ld (ix+ZX_ELLIPSE_DX+1),b
        ZX_ELLIPSE_STORE_DE ZX_ELLIPSE_DY

        ZX_ELLIPSE_LOAD_HL ZX_ELLIPSE_CX
        ZX_ELLIPSE_LOAD_DE ZX_ELLIPSE_RX
        call zx__ellipse_endpoints
        ZX_ELLIPSE_STORE_HL ZX_ELLIPSE_X0
        ZX_ELLIPSE_STORE_DE ZX_ELLIPSE_X1
        ZX_ELLIPSE_LOAD_HL ZX_ELLIPSE_CY
        ZX_ELLIPSE_LOAD_DE ZX_ELLIPSE_RY
        call zx__ellipse_endpoints
        ZX_ELLIPSE_STORE_HL ZX_ELLIPSE_Y0
        ZX_ELLIPSE_STORE_DE ZX_ELLIPSE_Y1

        ld a,(ix+ZX_ELLIPSE_RX)
        or (ix+ZX_ELLIPSE_RX+1)
        jr z,@line
        ld a,(ix+ZX_ELLIPSE_RY)
        or (ix+ZX_ELLIPSE_RY+1)
        jr z,@line
        call zx__ellipse_walk
        jr @finish
@line:
        ZX_ELLIPSE_LOAD_HL ZX_ELLIPSE_Y1
        push hl
        ZX_ELLIPSE_LOAD_HL ZX_ELLIPSE_X1
        push hl
        ZX_ELLIPSE_LOAD_HL ZX_ELLIPSE_Y0
        push hl
        ZX_ELLIPSE_LOAD_HL ZX_ELLIPSE_X0
        push hl
        ld c,(ix+ZX_ELLIPSE_DX)
        ld b,(ix+ZX_ELLIPSE_DX+1)
        ZX_ELLIPSE_LOAD_DE ZX_ELLIPSE_DY
        push iy
        pop hl
        call zx__line_clip
        ld sp,ix
@finish:
        ld hl,ZX_ELLIPSE_FRAME
        add hl,sp
        ld sp,hl
        pop iy
        pop ix
        jp ts__graphics_end_writer
@reject:
        pop ix
        ret

; Check the high byte of a center coordinate. Carry means out of range.
@center_range:
        cp 4
        jr nc,@negative
        or a
        ret
@negative:
        cp 0feh
        ret
ELSE
_zx_draw_ellipse_op:
zx__graphics_ellipse_op_a:
        ret
ENDIF
