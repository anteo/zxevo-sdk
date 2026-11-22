        MODULE bc__video_vline_pentagon
IFDEF BASECONF_VIDEO_PRIMITIVE_PACKED
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
EXTERN bc__video_line_zx_row
EXTERN bc__video_vline_packed_address
SECTION code_clib
PUBLIC bc__video_vline_pentagon

; Locates the starting packed pair of a Pentagon vertical line and enters the
; column painter.
;
; Model:
;
; address=page_base[(x>>1)&1]+zx__offset(y,x>>3)+((x&4)?0x2000:0);
; enter_packed_vertical_run(address);
;
; Tail backend uses the normalized IX axis frame: x +4, y +6, last +8,
; operation +10. An active prepared lease supplies aligned mapped CPU bases;
; coordinates have already been clipped. AF/BC/DE/HL volatile; return through
; video_line_return restores caller IX; IY is preserved.
; The pair's page uses x bit 1, 8 KiB plane uses bit 2, and left/right uses bit 0.
bc__video_vline_pentagon:
        call bc__video_line_zx_row
        jp bc__video_vline_packed_address
ENDIF
ENDIF
