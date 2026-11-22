        MODULE bc__video_hline_pentagon
IFDEF BASECONF_VIDEO_PRIMITIVE_PACKED
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
EXTERN bc__video_hline_packed_init
EXTERN bc__video_line_zx_row
SECTION code_clib
PUBLIC bc__video_hline_pentagon

; Seven local bytes: masks/paint -4..-1, part -5, row offset -7/-6.
; Compile only the selected mode's row formula. Neither entry needs a C request.
; Draws a Pentagon horizontal line by updating its packed pixel pairs on both
; pages.
;
; Model:
;
; row=zx__offset(y,0); for (part=0; part<4; ++part) {
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
bc__video_hline_pentagon:
        call bc__video_line_zx_row
        jp bc__video_hline_packed_init
ENDIF
ENDIF
