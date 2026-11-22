        MODULE bc__video_glyph_overlay_zx
IFDEF BASECONF_VIDEO_TEXT_ZX_BITMAP
EXTERN _bc_video_page0_base
EXTERN zx__cell_bitmap_address
EXTERN zx__font_overlay_rows
SECTION code_clib
PUBLIC bc__video_glyph_overlay_zx

; Overlay an aligned 8x8 glyph. ZX and Multicolor have the same bitmap layout.
bc__video_glyph_overlay_zx:
        ld de,(_bc_video_page0_base)
        call zx__cell_bitmap_address
        xor a
        ld c,0ffh
        jp zx__font_overlay_rows
ENDIF
