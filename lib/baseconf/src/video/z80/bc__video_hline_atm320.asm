        MODULE bc__video_hline_atm320
IFDEF BASECONF_VIDEO_PRIMITIVE_PACKED
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
EXTERN bc__video_hline_packed_init
EXTERN bc__video_line_linear_row
SECTION code_clib
PUBLIC bc__video_hline_atm320
; Draws an ATM320 horizontal line across the packed planes using their linear
; row addresses.
;
; Model:
;
; row=y*40; for (part=0; part<4; ++part) {
;     origin=page_base[part&1]+row+((part&2)?0x2000:0);
;     masks=select_endpoint_pixels(x0,x1,part*2); paint_span(origin+(x0>>3),origin+(x1>>3));
; }
;
; Tail backend uses the normalized IX axis frame: x +4, y +6, last +8,
; operation +10. An active prepared lease supplies aligned mapped CPU bases;
; coordinates have already been clipped. AF/BC/DE/HL volatile; return through
; video_line_return restores caller IX; IY is preserved.
; Seven private bytes: edge masks -1/-2,AND/XOR -3/-4,part -5,row_offset -7/-6.
; A physical byte stores two pixels: left mask 47h, right B8h; untouched endpoint
; pairs get zero masks, so partial groups never overwrite neighbouring pixels.
bc__video_hline_atm320:
        call bc__video_line_linear_row
        jp bc__video_hline_packed_init
ENDIF
ENDIF
