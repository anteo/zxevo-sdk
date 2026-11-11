IFDEF BASECONF_VIDEO_PRIMITIVE_PACKED
        MODULE bc__video_hline_packed
SECTION code_clib
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
PUBLIC bc__video_hline_pentagon
EXTERN bc__video_line_zx_row
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
PUBLIC bc__video_hline_atm320
EXTERN bc__video_line_linear_row
ENDIF
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base
EXTERN bc__video_line_packed_paint
EXTERN bc__video_hline_span
EXTERN bc__video_hline_run
EXTERN bc__video_line_return

; Seven local bytes: masks/paint -4..-1, part -5, row offset -7/-6.
; Compile only the selected mode's row formula. Neither entry needs a C request.
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
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
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
        jp bc__video_hline_packed_init
ENDIF
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
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
ENDIF
bc__video_hline_packed_init:
        push bc
        push bc
        push bc
        dec sp
        ld (ix-7),l
        ld (ix-6),h
        call bc__video_line_packed_paint
        ld (ix-3),b
        ld (ix-4),c
        xor a
        ld (ix-5),a
@part:
        call @masks
        ld l,(ix-7)
        ld h,(ix-6)
        bit 1,(ix-5)
        jr z,@plane
        set 5,h
@plane:
        ld de,(_bc_video_page0_base)
        bit 0,(ix-5)
        jr z,@origin
        ld de,(_bc_video_page1_base)
@origin:
        add hl,de
        ld a,3
        call bc__video_hline_span
        call bc__video_hline_run
        inc (ix-5)
        ld a,(ix-5)
        cp 4
        jr nz,@part
        jp bc__video_line_return

; Translate endpoint pixel selections directly into physical pair bit masks.
; Left field = 47h, right field = B8h. Zero masks skip untouched endpoint pairs.
;
; Selects which pixels of this packed pair are inside the line at each
; endpoint.
;
; Model:
;
; first_mask selects this part's pixels >=x0; last_mask selects pixels<=x1.
;
; For a single group the run ANDs both masks, giving the exact intersection.
; Input part=IX-5 and normalized endpoints; output IX-1/-2. AF/B volatile.
@masks:
        ld a,(ix-5)
        add a,a
        ld b,a                       ; part's left pixel within an eight-pixel group
        ld a,(ix+4)
        and 7
        cp b
        jr c,@first_full
        jr z,@first_full
        dec a
        cp b
        ld a,0
        jr nz,@first_store
        ld a,0B8h
        jr @first_store
@first_full:
        ld a,0FFh
@first_store:
        ld (ix-1),a
        ld a,(ix+8)
        and 7
        cp b
        ld a,0
        jr c,@last_store
        ld a,47h
        jr z,@last_store
        ld a,0FFh
@last_store:
        ld (ix-2),a
        ret
ENDIF
