        MODULE bc__video_pixel_pentagon
IFDEF BASECONF_VIDEO_MODE_PACKED
IFDEF BASECONF_VIDEO_MODE_ENABLED_PENTAGON_256
EXTERN bc__video_pixel_packed_address
EXTERN zx__bitmap_offset
SECTION code_clib
PUBLIC bc__video_pixel_pentagon

; Resolve a packed pixel address, then read, test or replace its color.
;
; offset = pentagon ? zx__offset(y,x>>3) : y*40+(x>>3);
; pair = page_base[(x>>1)&1]+offset+((x&4)?0x2000:0);
; if (op == COLOR) replace_only_selected_field(*pair,color);
; else { index=decode(*pair,x&1); return op == READ ? index : index != paper; }
;
; HL=x, DE=y, B=color, C=operation. In-range coordinates and prepared bases
; required. X bits 0/1/2 select field, page and plane. Save op/color while
; computing the offset. Return READ/TEST in L. Preserve IX/IY.
bc__video_pixel_pentagon:
        push bc
        ld c,e
        ld a,l
        push af
        rrca
        rrca
        rrca
        and 31
        ld e,a
        ld d,0
        call zx__bitmap_offset
        pop af
        jp bc__video_pixel_packed_address
ENDIF
ENDIF
