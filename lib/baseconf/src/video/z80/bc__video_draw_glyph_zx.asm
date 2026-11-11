IFDEF BASECONF_VIDEO_TEXT_ZX_BITMAP
        MODULE bc__video_draw_glyph_zx

SECTION code_clib
EXTERN _bc_video_page0_base
EXTERN zx__encode_attribute
EXTERN zx__cell_bitmap_address
EXTERN zx__font_overlay_rows

; Register ABI: HL = glyph, C = column, B = row, E = foreground,
; D = paper with bit 7 set for transparency. Pointer, lease and mode checked.
; Coordinates are in-range 8x8 cells. Preserve IX/IY, no static scratch.
IFDEF BASECONF_VIDEO_TEXT_ZX_256
PUBLIC bc__video_draw_glyph_zx
EXTERN zx__draw_cell

; Encode the lease's ink/paper, then draw an aligned cell on the common bitmap.
; HL=glyph, B=row, C=column, E=ink, D=paper. Preserve IX/IY.
bc__video_draw_glyph_zx:
        bit 7,d
        jr nz,bc_video_glyph_overlay_zx
        call zx__encode_attribute
        ld de,(_bc_video_page0_base)
        jp zx__draw_cell
ENDIF

IFDEF BASECONF_VIDEO_TEXT_ZX_MULTICOLOR
PUBLIC bc__video_draw_glyph_multicolor
; Writes an eight-by-eight Multicolor glyph and sets a separate attribute
; byte for each scanline.
;
; Model:
;
; bitmap=page0_base+zx__offset(row*8,column);
; if (transparent) overlay_glyph(bitmap,glyph);
; else copy glyph rows and write each raster's attribute at bitmap_address+0x2000;
;
; Native inputs: HL=glyph[8], C=column, B=row, E=ink, D=paper/overlay.
; Dispatcher has checked the pointer/lease/mode; caller supplies an in-bounds
; 8x8 cell and both mapped pages. AF/BC/DE/HL volatile; IX/IY preserved.
; No clipping, page remapping or persistent global scratch.
; Cell alignment keeps all eight raster rows within one ZX character row;
; INC D is sufficient. Bitmap bits stay literal even when a color equals paper.
bc__video_draw_glyph_multicolor:
        bit 7,d
        jr nz,bc_video_glyph_overlay_zx
        call zx__encode_attribute
        push hl                      ; glyph
        push af                      ; attribute
        ld de,(_bc_video_page0_base)
        call zx__cell_bitmap_address
        pop af
        ld c,a
        pop hl
        ld b,8
@row:
        ld a,(hl)
        inc hl
        ld (de),a
        ld a,d
        add a,20h
        ld d,a
        ld a,c
        ld (de),a                    ; attribute for this scanline
        ld a,d
        sub 20h
        ld d,a
        inc d
        djnz @row
        ret
ENDIF

; Overlay an aligned 8x8 glyph. ZX and Multicolor have the same bitmap layout.
bc_video_glyph_overlay_zx:
        ld de,(_bc_video_page0_base)
        call zx__cell_bitmap_address
        xor a
        ld c,0ffh
        jp zx__font_overlay_rows
ENDIF
