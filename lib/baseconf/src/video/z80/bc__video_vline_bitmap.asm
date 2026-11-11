IFDEF BASECONF_VIDEO_PRIMITIVE_BITMAP
        MODULE bc__video_vline_bitmap
SECTION code_clib
PUBLIC bc__video_vline_bitmap
EXTERN bc__video_line_bitmap_paint
EXTERN bc__video_pixel_mask
EXTERN bc__video_line_partial_paint
EXTERN bc__video_vline_draw

; HL = first bitmap byte. Precompute the selected-bit operation once.
;
; Prepares a paint operation for the selected bitmap bit and runs it down the
; column.
;
; Model:
;
; paint=restrict_to_mask(bitmap_operation(op),0x80>>(x&7));
; vertical_run(bitmap,paint);
;
; Tail backend uses the normalized IX axis frame: x +4, y +6, last +8,
; operation +10. An active prepared lease supplies aligned mapped CPU bases;
; coordinates have already been clipped. AF/BC/DE/HL volatile; return through
; video_line_return restores caller IX; IY is preserved.
; Bitmap address is temporarily pushed while mask helpers clobber HL.
bc__video_vline_bitmap:
        push hl
        call bc__video_line_bitmap_paint
        ld a,(ix+4)
        and 7
        call bc__video_pixel_mask
        call bc__video_line_partial_paint
        pop hl
        jp bc__video_vline_draw
ENDIF
