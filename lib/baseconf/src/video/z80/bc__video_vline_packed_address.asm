        MODULE bc__video_vline_packed_address
IFDEF BASECONF_VIDEO_PRIMITIVE_PACKED
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base
EXTERN bc__video_line_shift_x
EXTERN bc__video_vline_packed
SECTION code_clib
PUBLIC bc__video_vline_packed_address
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
