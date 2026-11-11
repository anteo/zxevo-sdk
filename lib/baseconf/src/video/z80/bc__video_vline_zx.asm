IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_BITMAP
        MODULE bc__video_vline_zx
SECTION code_clib
PUBLIC bc__video_vline_zx
EXTERN _bc_video_page0_base
EXTERN bc__video_line_zx_row
EXTERN bc__video_line_shift_x
EXTERN bc__video_vline_bitmap

; Locates the first ZX bitmap byte of a vertical line and enters the masked
; painter.
;
; Model:
;
; bitmap=page0_base+zx__offset(y,x>>3); enter_bitmap_vertical_run(bitmap);
;
; Tail backend uses the normalized IX axis frame: x +4, y +6, last +8,
; operation +10. An active prepared lease supplies aligned mapped CPU bases;
; coordinates have already been clipped. AF/BC/DE/HL volatile; return through
; video_line_return restores caller IX; IY is preserved.
bc__video_vline_zx:
        call bc__video_line_zx_row
        ld e,(ix+4)
        ld d,(ix+5)
        ld b,3
        call bc__video_line_shift_x
        add hl,de
        ld de,(_bc_video_page0_base)
        add hl,de
        jp bc__video_vline_bitmap
ENDIF
