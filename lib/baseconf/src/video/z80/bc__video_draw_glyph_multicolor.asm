        MODULE bc__video_draw_glyph_multicolor
IFDEF BASECONF_VIDEO_TEXT_ZX_BITMAP
IFDEF BASECONF_VIDEO_TEXT_ZX_MULTICOLOR
EXTERN _bc_video_page0_base
EXTERN bc__video_glyph_overlay_zx
EXTERN zx__cell_bitmap_address
EXTERN zx__encode_attribute
SECTION code_clib
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
        jp nz,bc__video_glyph_overlay_zx
        call zx__encode_attribute
        push af                      ; attribute
        ld de,(_bc_video_page0_base)
        call zx__cell_bitmap_address
        pop af
        ld c,a
        ld b,8
@row:
        ld a,(hl)
        inc hl
        ld (de),a
        set 5,d                      ; second 8 KiB of the same aligned window
        ld a,c
        ld (de),a                    ; attribute for this scanline
        res 5,d
        inc d
        djnz @row
        ret
ENDIF
ENDIF
