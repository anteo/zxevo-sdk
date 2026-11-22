        MODULE bc__video_text_attribute_planes
INCLUDE "video/text_rows.inc"
EXTERN bc__video_text_planes_select
SECTION code_clib
PUBLIC bc__video_text_attribute_planes

bc__video_text_attribute_planes:
        ld c,(ix+BC_TEXT_ROWS_PAGE0)
        ld a,(ix+BC_TEXT_ROWS_MODE)
        cp 5
        ld hl,31C0h
        ld de,21C1h
        jp nz,bc__video_text_planes_select
        ld hl,21C0h
        ld de,01C1h
        jp bc__video_text_planes_select
