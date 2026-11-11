IFDEF BASECONF_VIDEO_MODE_PACKED
        MODULE bc__video_pixel_packed
SECTION code_clib
IFDEF BASECONF_VIDEO_MODE_ENABLED_PENTAGON_256
PUBLIC bc__video_pixel_pentagon
EXTERN zx__bitmap_offset
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_320
PUBLIC bc__video_pixel_atm320
EXTERN bc__video_pixel_linear_offset
ENDIF
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base
EXTERN zx__paper
EXTERN bc__video_packed_pixel_color_regs
EXTERN bc__video_packed_pixels_regs
EXTERN bc__video_pixel_bool_return

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
IFDEF BASECONF_VIDEO_MODE_ENABLED_PENTAGON_256
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
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_320
        jr bc__video_pixel_packed_address
ENDIF
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_320
bc__video_pixel_atm320:
        push bc
        ld b,3
        call bc__video_pixel_linear_offset
ENDIF
bc__video_pixel_packed_address:
        bit 2,a
        jr z,@plane
        set 5,h
@plane:
        ld de,(_bc_video_page0_base)
        bit 1,a
        jr z,@page
        ld de,(_bc_video_page1_base)
@page:
        add hl,de
        and 1
        ld e,a
        pop bc
        ld a,c
        cp 4
        jr z,@color
        push af                      ; carry distinguishes READ=3 from TEST=5
        ld a,(hl)
        call bc__video_packed_pixel_color_regs
        ld l,a
        pop af
        ret c
        ld a,(zx__paper)
        xor l
        jp bc__video_pixel_bool_return
@color:
        ld a,e
        or a
        ld e,b
        ld d,0
        ld b,0B8h                    ; retain the right field when writing left
        jr z,@encode
        ld d,e
        ld e,0
        ld b,47h
@encode:
        call bc__video_packed_pixels_regs
        ld c,a
        ld a,(hl)
        and b
        or c
        ld (hl),a
        ret
ENDIF
