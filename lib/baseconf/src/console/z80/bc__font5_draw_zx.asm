        MODULE bc__font5_draw_zx
IFDEF BASECONF_VIDEO_TEXT_ZX_BITMAP
EXTERN _bc_video_page0_base
EXTERN bc__font5_bitmap_masks
EXTERN bc__font5_draw_return
EXTERN zx__attribute_address
EXTERN zx__bitmap_offset
EXTERN zx__draw_font5_cell
EXTERN zx__encode_attribute
EXTERN zx__font_overlay_rows
INCLUDE "console/font5_bitmap.inc"
SECTION code_clib
PUBLIC bc__font5_draw_zx

; Tail entry from the dispatcher: IX is the callback frame, SP=IX-5,
; glyph/width/height/background are initialized. Preserve IX/IY on final return.
;
; Draws a glyph at a pixel position on the ZX screen and colors the character
; cells it touches.
;
; Model:
;
; initial_bitmap=page0_base+zx__offset(y,x>>3); bitmap=initial_bitmap;
; if (width==5 && height==8 && opaque && !(x&1) && !(y&7)) return draw_5x8_cell();
; for each glyph row merge bits and advance the ZX raster address;
; if (opaque) write the attribute at each touched cell;
;
; Active lease, in-bounds glyph and dispatcher/bitmap contexts are required.
; The lease supplies the aligned page0 base. Page selection stays unchanged.
; AF/BC/DE/HL volatile; shared epilogue restores IX/IY. ZX raster stepping
; first increments H, then fixes the character-row/third boundary on wrap.
; Below IX-5 are the attribute/shift and span/glyph-mask words. Only the
; generic loop pushes the keep masks and saves the initial bitmap address
; for the attribute pass. It consumes HEIGHT as its row counter.
bc__font5_draw_zx:
        ld e,(ix+11)
        ld d,(ix+12)
        call zx__encode_attribute
        ld b,a
        ld a,(ix+4)
        and 7
        ld c,a
        push bc                      ; attribute, shift
        add a,(ix+BC_FONT5_WIDTH)
        ld b,a
        push bc                      ; span, space for the unshifted mask
        ld de,(_bc_video_page0_base) ; D is the aligned window high byte
        ld a,(ix+4)                  ; an in-bounds ZX x fits in one byte
        rrca
        rrca
        rrca
        and 1Fh
        ld e,a
        ld c,(ix+6)
        call zx__bitmap_offset

        ld a,(ix+BC_FONT5_WIDTH)
        cp 5
        jr nz,@generic
        ld a,(ix+BC_FONT5_HEIGHT)
        cp 8
        jr nz,@generic
        bit 0,(ix+BC_FONT5_BACKGROUND)
        jr nz,@generic
        ld a,(ix+BC_FONT5_SHIFT)
        and 1
        jr nz,@generic
        ld a,(ix+6)
        and 7
        jr nz,@generic
        ex de,hl
        ld l,(ix+BC_FONT5_SOURCE)
        ld h,(ix+BC_FONT5_SOURCE+1)
        ld a,(ix+BC_FONT5_SHIFT)
        ld c,(ix+BC_FONT5_ATTRIBUTE)
        call zx__draw_font5_cell
        jp bc__font5_draw_return
@generic:
        push hl
        call bc__font5_bitmap_masks
        pop hl
        ld (ix+BC_FONT5_GLYPH_MASK),a
        bit 0,(ix+BC_FONT5_BACKGROUND)
        jr nz,@overlay
        ld a,b
        cpl
        ld b,a
        ld a,c
        cpl
        ld c,a
        jr @raster
@overlay:
        ld a,(ix+BC_FONT5_HEIGHT)
        cp 8
        jr nz,@overlay_masks
        ld a,(ix+6)
        and 7
        jr nz,@overlay_masks
        ex de,hl
        ld l,(ix+BC_FONT5_SOURCE)
        ld h,(ix+BC_FONT5_SOURCE+1)
        ld a,(ix+BC_FONT5_SHIFT)
        ld c,(ix+BC_FONT5_GLYPH_MASK)
        call zx__font_overlay_rows
        jp bc__font5_draw_return
@overlay_masks:
        ld bc,0ffffh
@raster:
        push bc                      ; persistent keep masks for the generic loop
        push hl
        ld e,(ix+BC_FONT5_SOURCE)
        ld d,(ix+BC_FONT5_SOURCE+1)
@row:
        ld a,(de)
        inc de
        and (ix+BC_FONT5_GLYPH_MASK)
        ld c,0
        ld b,(ix+BC_FONT5_SHIFT)
        inc b
        jr @shift_test
@shift_pixels:
        srl a
        rr c
@shift_test:
        djnz @shift_pixels
        ld b,a
        ld a,(hl)
        and (ix+BC_FONT5_KEEP_FIRST)
        or b
        ld (hl),a
        ld a,(ix+BC_FONT5_SPAN)
        cp 9
        jr c,@row_done
        inc hl                       ; consecutive ZX bytes on this scanline
        ld a,(hl)
        and (ix+BC_FONT5_KEEP_SECOND)
        or c
        ld (hl),a
        dec hl
@row_done:
        call @next_row
        dec (ix+BC_FONT5_HEIGHT)
        jr nz,@row
        pop hl
        bit 0,(ix+BC_FONT5_BACKGROUND)
        jp nz,bc__font5_draw_return
        call zx__attribute_address
        ex de,hl
        ld a,(ix+BC_FONT5_SPAN)
        cp 9
        ld a,(ix+BC_FONT5_ATTRIBUTE)
        ld (hl),a
        jp c,bc__font5_draw_return
        inc hl
        ld (hl),a
        jp bc__font5_draw_return

@next_row:
        inc h
        ld a,h
        and 7
        ret nz
        ld a,l
        add a,32
        ld l,a
        jr nc,@same_third
        res 5,h
        ret
@same_third:
        ld a,h
        sub 8
        ld h,a
        ret
ENDIF
