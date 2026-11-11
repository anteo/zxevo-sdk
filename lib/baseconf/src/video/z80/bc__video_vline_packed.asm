IFDEF BASECONF_VIDEO_PRIMITIVE_PACKED
        MODULE bc__video_vline_packed
SECTION code_clib
PUBLIC bc__video_vline_packed
EXTERN bc__video_line_packed_paint
EXTERN bc__video_line_partial_paint
EXTERN bc__video_vline_draw

; HL = first packed pair. Encode once, then update only its selected pixel.
;
; Paints one pixel of each packed pair down a column while keeping the
; adjacent pixel intact.
;
; Model:
;
; paint=restrict_to_mask(packed_operation(op),(x&1)?0xb8:0x47);
; vertical_run(pair_address,paint);
;
; Tail backend uses the normalized IX axis frame: x +4, y +6, last +8,
; operation +10. An active prepared lease supplies aligned mapped CPU bases;
; coordinates have already been clipped. AF/BC/DE/HL volatile; return through
; video_line_return restores caller IX; IY is preserved.
; Encoding and selected-bit masking happen once per line, not per raster row.
bc__video_vline_packed:
        call bc__video_line_packed_paint
        ld a,47h                     ; left field: bits 0,1,2,6
        bit 0,(ix+4)
        jr z,@mask
        ld a,0B8h                    ; right field: bits 3,4,5,7
@mask:
        call bc__video_line_partial_paint
        jp bc__video_vline_draw
ENDIF
