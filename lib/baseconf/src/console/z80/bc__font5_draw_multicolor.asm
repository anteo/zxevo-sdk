        MODULE bc__font5_draw_multicolor
IFDEF BASECONF_VIDEO_TEXT_ZX_MULTICOLOR
INCLUDE "console/font5_bitmap.inc"
SECTION code_clib
PUBLIC bc__font5_draw_multicolor
EXTERN bc__font5_draw_pixels
EXTERN bc__font5_draw_return
EXTERN _bc_video_operation_depth
EXTERN _bc_video_page0_base
EXTERN zx__ink
EXTERN zx__bitmap_offset
EXTERN zx__draw_font5_rows
EXTERN zx__encode_attribute

; Draw an opaque 5x8 console glyph and color each occupied byte on every raster.
;
; if (size != 5x8 || (x & 1) || (y & 7)) return draw_pixels();
; if (paper != current_paper || (ink != paper && ink != current_ink)) return draw_pixels();
; bits = ink == paper ? blank : glyph;
; if (an attribute write may overwrite a glyph row) return draw_pixels();
; draw_font5_rows(bits, bitmap, x & 7);
; for (r = 0; r < 8; ++r) {
;     attr = bitmap + 0x2000 + 256*r;
;     attr[0] = color; if ((x & 7) >= 4) attr[1] = color;
; }
;
; Tail entry from the opaque Multicolor dispatcher. IX anchors the font
; callback, SP=IX-5. The complete glyph fits the mapped ZX-layout bitmap.
; The pixel writer clears bits painted in the current paper color and uses
; the current ink for their attributes. Direct callbacks with other colors
; retain the pixel writer's per-byte attribute selection.
; Save the attribute, shift and bitmap address across the shared row writer.
; AF/BC/DE/HL volatile, IX/IY restored by the common epilogue.
bc__font5_draw_multicolor:
        ld a,(_bc_video_operation_depth)
        or a
        jp z,bc__font5_draw_return
        ld a,(ix+BC_FONT5_WIDTH)
        cp 5
        jp nz,bc__font5_draw_pixels
        ld a,(ix+BC_FONT5_HEIGHT)
        cp 8
        jp nz,bc__font5_draw_pixels
        bit 0,(ix+4)
        jp nz,bc__font5_draw_pixels
        ld a,(ix+6)
        and 7
        jp nz,bc__font5_draw_pixels

        ld de,(zx__ink)              ; E=current ink, D=current paper
        ld a,(ix+12)
        cp d
        jp nz,bc__font5_draw_pixels
        ld a,(ix+11)
        cp d
        ld hl,blank_rows
        jr z,@source
        cp e
        jp nz,bc__font5_draw_pixels
        ld l,(ix+BC_FONT5_SOURCE)
        ld h,(ix+BC_FONT5_SOURCE+1)
@source:
        push hl
        call zx__encode_attribute
        ld b,a
        ld a,(ix+4)
        rrca
        rrca
        rrca
        and 31
        ld e,a
        ld a,(_bc_video_page0_base+1)
        ld d,a
        ld c,(ix+6)
        call zx__bitmap_offset
        ex de,hl                     ; DE=bitmap, HL=glyph after POP
        pop hl
        ; The attribute pass follows the bitmap pass. Keep raster write order
        ; if a RAM font overlaps these attributes: the eight source bytes can
        ; start in the preceding 256-byte block, up to seven bytes before a write.
        ld a,h
        sub d
        sub 1fh                      ; attribute high bytes are D+20h..D+27h
        cp 9
        jr nc,@draw
        ld a,e
        sub l
        inc a                        ; first column - source low is in [-1,7]
        cp 9
        jp c,bc__font5_draw_pixels
@draw:
        ld a,(ix+4)
        and 7
        ld c,a
        push de
        push bc
        call zx__draw_font5_rows
        pop bc
        pop hl
        set 5,h                      ; attributes at bitmap+0x2000 in the same window
        ld a,c
        ld c,b
        ld b,8
        cp 4
        jr c,@one_byte
@two_bytes:
        ld (hl),c
        inc l
        ld (hl),c
        dec l
        inc h
        djnz @two_bytes
        jp bc__font5_draw_return
@one_byte:
        ld (hl),c
        inc h
        djnz @one_byte
        jp bc__font5_draw_return

SECTION rodata_clib
blank_rows:
        defs 8,0
ENDIF
