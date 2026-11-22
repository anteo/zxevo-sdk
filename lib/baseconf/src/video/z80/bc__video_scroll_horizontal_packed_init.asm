        MODULE bc__video_scroll_horizontal_packed_init
IFDEF BASECONF_VIDEO_PRIMITIVE_PACKED
INCLUDE "video/scroll_horizontal.inc"
EXTERN _bc_video_cached_height
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base
EXTERN bc__video_packed_pixels_regs
EXTERN bc__video_scroll_horizontal_return
EXTERN bc__video_scroll_packed_row
EXTERN zx__paper
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
EXTERN bc__video_row_offset_40
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
EXTERN zx__bitmap_offset
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
EXTERN _bc_video_draw_surface_state
ENDIF
ENDIF
SECTION code_clib
PUBLIC bc__video_scroll_horizontal_packed_init
bc__video_scroll_horizontal_packed_init:
        ld hl,-BC_SCROLL_PACKED_LOCALS
        add hl,sp
        ld sp,hl
        ld (ix+BC_SCROLL_PAIR_COUNT),a
        ld a,(zx__paper)
        ld e,a
        ld d,a
        call bc__video_packed_pixels_regs
        ld (ix+BC_SCROLL_BLANK),a
        ld a,(_bc_video_page0_base+1)
        ld b,a
        ld a,(_bc_video_page1_base+1)
        xor b
        ld (ix+BC_SCROLL_PAGE_XOR),a
        xor a
        ld (ix+BC_SCROLL_Y),a
@row:
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
        ld a,(_bc_video_draw_surface_state)
        cp 2
        jr nz,@linear
ENDIF
        ld c,(ix+BC_SCROLL_Y)
        ld de,0
        call zx__bitmap_offset
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
        jr @origin
@linear:
ENDIF
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
        ld a,(ix+BC_SCROLL_Y)
        call bc__video_row_offset_40
ENDIF
@origin:
        ld de,(_bc_video_page0_base)
        add hl,de
        call bc__video_scroll_packed_row
        inc (ix+BC_SCROLL_Y)
        ld a,(_bc_video_cached_height)
        cp (ix+BC_SCROLL_Y)
        jr nz,@row
        jp bc__video_scroll_horizontal_return
ENDIF
