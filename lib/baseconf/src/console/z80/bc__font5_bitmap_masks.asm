        MODULE bc__font5_bitmap_masks
IFDEF BASECONF_VIDEO_TEXT_ZX_BITMAP
defc BC_FONT5_BITMAP = 1
ELSE
IFDEF BASECONF_VIDEO_TEXT_ATM_640
defc BC_FONT5_BITMAP = 1
ENDIF
ENDIF
IFDEF BC_FONT5_BITMAP
SECTION code_clib
PUBLIC bc__font5_bitmap_masks

; Prepare the generic row masks. The specialized 5x8 ZX kernel skips this.
;
; Builds the masks used to keep pixels outside the glyph intact and to leave
; the background untouched for transparent glyphs.
;
; Model:
;
; glyph_mask=0xff<<(8-width); clear_mask=opaque ?
; ((uint16_t)glyph_mask<<8)>>shift : 0.
;
; Width is 1..8 and shift is 0..7. Clear masks D/E protect neighbouring pixels;
; transparent glyphs clear nothing. AF/B/DE volatile; IX/IY preserved.
bc__font5_bitmap_masks:
        ld b,(ix-3)
        xor a
@width_mask:
        scf
        rra
        djnz @width_mask
        ld (ix-13),a
        ld d,a
        ld e,0
        ld a,(ix-6)
        or a
        jr z,@masks_ready
        ld b,a
@shift_mask:
        srl d
        rr e
        djnz @shift_mask
@masks_ready:
        bit 0,(ix-5)                 ; transparent text only ORs glyph pixels
        jr z,@opaque
        ld de,0
@opaque:
        ld (ix-14),d
        ld (ix-15),e
        ret
ENDIF
