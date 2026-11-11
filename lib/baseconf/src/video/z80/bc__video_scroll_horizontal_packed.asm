IFDEF BASECONF_VIDEO_PRIMITIVE_PACKED
        MODULE bc__video_scroll_horizontal_packed
INCLUDE "video/scroll_horizontal.inc"
SECTION code_clib
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
PUBLIC bc__video_scroll_horizontal_pentagon
EXTERN zx__bitmap_offset
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
PUBLIC bc__video_scroll_horizontal_atm320
EXTERN bc__video_row_offset_40
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
EXTERN _bc_video_draw_surface_state
ENDIF
ENDIF
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base
EXTERN zx__paper
EXTERN _bc_video_cached_height
EXTERN bc__video_packed_pixels_regs
EXTERN bc__video_scroll_packed_row
EXTERN bc__video_scroll_horizontal_return

; Shifts packed Pentagon or ATM320 rows horizontally and fills the exposed
; pixels with paper color.
;
; C model:
;
;   paper_pair = pack(paper, paper);
;   for (y = 0; y < height; ++y)
;       shift_native_pairs(page0_base + row_offset(y), width/2, pixels, right);
;
; Seven persistent stack bytes (scroll_horizontal.inc), no full-row scratch.
; Entry from the dispatcher with an active lease. Preserve IX/IY on return.
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
bc__video_scroll_horizontal_pentagon:
        ld a,128
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
        jp bc__video_scroll_horizontal_packed_init
ENDIF
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
bc__video_scroll_horizontal_atm320:
        ld a,160
ENDIF
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
