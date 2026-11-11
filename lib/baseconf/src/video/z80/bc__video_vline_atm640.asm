IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
        MODULE bc__video_vline_atm640
SECTION code_clib
PUBLIC bc__video_vline_atm640
EXTERN _bc_video_page1_base
EXTERN bc__video_line_linear_row
EXTERN bc__video_line_shift_x
EXTERN bc__video_vline_bitmap

; Locates the first ATM640 bitmap byte of a vertical line and enters the
; masked painter.
;
; Model:
;
; bitmap=page1_base+y*40+(x>>4)+((x&8)?0x2000:0); enter_bitmap_vertical_run(bitmap);
;
; Tail backend uses the normalized IX axis frame: x +4, y +6, last +8,
; operation +10. An active prepared lease supplies aligned mapped CPU bases;
; coordinates have already been clipped. AF/BC/DE/HL volatile; return through
; video_line_return restores caller IX; IY is preserved.
bc__video_vline_atm640:
        call bc__video_line_linear_row
        ld e,(ix+4)
        ld d,(ix+5)
        ld b,4
        call bc__video_line_shift_x
        add hl,de
        bit 3,(ix+4)
        jr z,@plane
        set 5,h
@plane:
        ld de,(_bc_video_page1_base)
        add hl,de
        jp bc__video_vline_bitmap
ENDIF
