        MODULE zx_draw_line_op
SECTION code_graphics
PUBLIC _zx_draw_line_op
PUBLIC zx__graphics_line_op_a
IFDEF TSCONF_VIDEO_BITMAP
EXTERN ts__graphics_begin_writer
EXTERN ts__graphics_end_writer
EXTERN zx__line_clip
ENDIF

; Clip an inclusive line and apply the selected writer along its raster path.
;
; writer = begin_writer(operation);
; if (writer) { line_clip(endpoints, width, height, writer); end_writer(); }
;
; SDCC endpoint words at SP+2..+9, operation at +10.
; IX anchors the caller's arguments. The four copies beneath it are the
; common line kernel's outgoing argument block. The shorthand entry takes
; the operation in A. Preserve IX/IY.
_zx_draw_line_op:
IFDEF TSCONF_VIDEO_BITMAP
        ld hl,10
        add hl,sp
        ld a,(hl)
ENDIF
zx__graphics_line_op_a:
IFDEF TSCONF_VIDEO_BITMAP
        call ts__graphics_begin_writer
        ret c
        push ix
        ld ix,0
        add ix,sp
        push hl                      ; IX-2 = writer
        ld l,(ix+10)
        ld h,(ix+11)
        push hl
        ld l,(ix+8)
        ld h,(ix+9)
        push hl
        ld l,(ix+6)
        ld h,(ix+7)
        push hl
        ld l,(ix+4)
        ld h,(ix+5)
        push hl
        ld l,(ix-2)
        ld h,(ix-1)
        call zx__line_clip
        ld sp,ix
        pop ix
        jp ts__graphics_end_writer
ELSE
        ret
ENDIF
