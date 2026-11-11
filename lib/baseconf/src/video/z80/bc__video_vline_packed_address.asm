IFDEF BASECONF_VIDEO_PRIMITIVE_PACKED
        MODULE bc__video_vline_packed_address
SECTION code_clib
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
PUBLIC bc__video_vline_pentagon
EXTERN bc__video_line_zx_row
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
PUBLIC bc__video_vline_atm320
EXTERN bc__video_line_linear_row
ENDIF
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base
EXTERN bc__video_line_shift_x
EXTERN bc__video_vline_packed

IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
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
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
        jp bc__video_vline_packed_address
ENDIF
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
; Locates the starting packed pair of an ATM320 vertical line and enters the
; column painter.
;
; Model:
;
; address=page_base[(x>>1)&1]+y*40+(x>>3)+((x&4)?0x2000:0);
; enter_packed_vertical_run(address);
;
; Tail backend uses the normalized IX axis frame: x +4, y +6, last +8,
; operation +10. An active prepared lease supplies aligned mapped CPU bases;
; coordinates have already been clipped. AF/BC/DE/HL volatile; return through
; video_line_return restores caller IX; IY is preserved.
; The pair's page uses x bit 1, 8 KiB plane uses bit 2, and left/right uses bit 0.
bc__video_vline_atm320:
        call bc__video_line_linear_row
ENDIF
bc__video_vline_packed_address:
        ld e,(ix+4)
        ld d,(ix+5)
        ld b,3
        call bc__video_line_shift_x
        add hl,de
        bit 2,(ix+4)
        jr z,@plane
        set 5,h
@plane:
        ld de,(_bc_video_page0_base)
        bit 1,(ix+4)
        jr z,@page
        ld de,(_bc_video_page1_base)
@page:
        add hl,de
        jp bc__video_vline_packed
ENDIF
