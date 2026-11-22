        MODULE bc__font5_bitmap_row
IFDEF BASECONF_VIDEO_TEXT_ZX_BITMAP
defc BC_FONT5_BITMAP = 1
ELSE
IFDEF BASECONF_VIDEO_TEXT_ATM_640
defc BC_FONT5_BITMAP = 1
ENDIF
ENDIF
IFDEF BC_FONT5_BITMAP
SECTION code_clib
PUBLIC bc__font5_bitmap_row

; Draw one raster row using cached addresses/masks; advance the glyph pointer.
; Each mode owns its vertical address advance and attribute writes.
;
; Merges one glyph scanline into one or two bitmap bytes and advances the
; glyph source.
;
; Model:
;
; bits=(*glyph++ & glyph_mask); aligned=((uint16_t)bits<<8)>>shift;
; bitmap[0]=(bitmap[0]&~clear0)|(aligned>>8);
; if (width+shift>8) bitmap[spill_delta]=(bitmap[spill_delta]&~clear1)|(uint8_t)aligned;
;
; Caller owns the active mapped bitmap page and advances each raster address.
; AF/BC/DE/HL volatile, IX/IY preserved. This helper advances only the glyph.
bc__font5_bitmap_row:
        ld l,(ix-2)
        ld h,(ix-1)
        ld a,(hl)
        and (ix-13)
        inc hl
        ld (ix-2),l
        ld (ix-1),h
        ld d,a
        ld e,0
        ld a,(ix-6)
        or a
        jr z,@shifted
        ld b,a
@shift_pixels:
        srl d
        rr e
        djnz @shift_pixels
@shifted:
        ld l,(ix-8)
        ld h,(ix-7)
        ld a,(ix-14)
        cpl
        and (hl)
        or d
        ld (hl),a
        ld a,(ix-16)
        cp 9
        ret c
        ld c,(ix-12)
        ld b,(ix-11)
        add hl,bc
        ld a,(ix-15)
        cpl
        and (hl)
        or e
        ld (hl),a
        ret
ENDIF
