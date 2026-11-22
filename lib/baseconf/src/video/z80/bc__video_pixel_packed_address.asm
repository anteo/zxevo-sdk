        MODULE bc__video_pixel_packed_address
IFDEF BASECONF_VIDEO_MODE_PACKED
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base
EXTERN bc__video_packed_pixel_color_regs
EXTERN bc__video_packed_pixels_regs
EXTERN bc__video_pixel_bool_return
EXTERN zx__paper
SECTION code_clib
PUBLIC bc__video_pixel_packed_address
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
