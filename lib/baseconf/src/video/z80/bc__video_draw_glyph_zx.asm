        MODULE bc__video_draw_glyph_zx
IFDEF BASECONF_VIDEO_TEXT_ZX_BITMAP
IFDEF BASECONF_VIDEO_TEXT_ZX_256
EXTERN _bc_video_page0_base
EXTERN bc__video_glyph_overlay_zx
EXTERN zx__draw_cell
EXTERN zx__encode_attribute
SECTION code_clib
PUBLIC bc__video_draw_glyph_zx

; Register ABI: HL = glyph, C = column, B = row, E = foreground,
; D = paper with bit 7 set for transparency. Pointer, lease and mode checked.
; Coordinates are in-range 8x8 cells. Preserve IX/IY, no static scratch.

; Encode the lease's ink/paper, then draw an aligned cell on the common bitmap.
; HL=glyph, B=row, C=column, E=ink, D=paper. Preserve IX/IY.
bc__video_draw_glyph_zx:
        bit 7,d
        jp nz,bc__video_glyph_overlay_zx
        call zx__encode_attribute
        ld de,(_bc_video_page0_base)
        jp zx__draw_cell
ENDIF
ENDIF
