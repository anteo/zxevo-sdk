        MODULE bc__font5_bitmap_masks
IFDEF BASECONF_VIDEO_TEXT_ZX_BITMAP
defc BC_FONT5_BITMAP = 1
ELSE
IFDEF BASECONF_VIDEO_TEXT_ATM_640
defc BC_FONT5_BITMAP = 1
ENDIF
ENDIF
IFDEF BC_FONT5_BITMAP
INCLUDE "console/font5_bitmap.inc"
SECTION code_clib
PUBLIC bc__font5_bitmap_masks
EXTERN zx__edge_masks

; Split the glyph width across the first and (if needed) second bitmap byte.
;
; glyph_mask = ~(0xff >> width);
; fields = ((uint16_t)glyph_mask << 8) >> (x & 7);
;
; IX anchors the callback (width 1..8). Return B/C = first/second field,
; A = unshifted glyph mask, DE = x & 7. HL and flags volatile; IX/IY preserved.
bc__font5_bitmap_masks:
        ld e,(ix+BC_FONT5_WIDTH)
        ld d,0
        ld hl,zx__edge_masks
        add hl,de
        ld a,(hl)
        cpl
        ld b,a
        ld c,0
        ld a,(ix+4)
        and 7
        ld e,a
        ld a,b
        ret z
        ld d,e
@shift:
        srl b
        rr c
        dec d                        ; ends at zero, leaving DE = shift
        jr nz,@shift
        ret
ENDIF
