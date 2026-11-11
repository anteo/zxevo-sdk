        MODULE zx_draw_plot_op
SECTION code_graphics
PUBLIC _zx_draw_plot_op
PUBLIC zx__graphics_plot_op_a
IFDEF TSCONF_VIDEO_BITMAP
EXTERN ts__graphics_begin_writer
EXTERN ts__graphics_end_writer
ENDIF

; Draw one clipped pixel, or apply an explicit pixel operation.
;
; writer = begin_writer(operation);
; if (writer) { writer(x, y); end_writer(); }
;
; SDCC signed x/y at SP+2/+4, operation at SP+6.
; Shorthands pass the operation in A. The stack saves IX while it holds
; the selected callback. Preserve IX/IY.
_zx_draw_plot_op:
IFDEF TSCONF_VIDEO_BITMAP
        ld hl,6
        add hl,sp
        ld a,(hl)
ENDIF
zx__graphics_plot_op_a:
IFDEF TSCONF_VIDEO_BITMAP
        call ts__graphics_begin_writer
        ret c
        push ix
        push hl
        pop ix
        ld hl,4
        add hl,sp
        ld c,(hl)
        inc hl
        ld b,(hl)
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld h,b
        ld l,c
        call @write
        pop ix
        jp ts__graphics_end_writer
@write:
        jp (ix)
ELSE
        ret
ENDIF
