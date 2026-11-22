        MODULE bc__video_packed_cursor_prev
IFDEF BASECONF_VIDEO_PRIMITIVE_PACKED
INCLUDE "video/scroll_horizontal.inc"
SECTION code_clib
PUBLIC bc__video_packed_cursor_prev

bc__video_packed_cursor_prev:
        ld a,c
        and 3
        jr nz,@same_group
        dec hl
@same_group:
        bit 0,c
        jr nz,@page
        ld a,h
        xor 20h
        ld h,a
@page:
        ld a,h
        xor (ix+BC_SCROLL_PAGE_XOR)
        ld h,a
        dec c
        ret
ENDIF
