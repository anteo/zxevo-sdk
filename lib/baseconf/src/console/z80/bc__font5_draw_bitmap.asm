IFDEF BASECONF_VIDEO_TEXT_ZX_BITMAP
defc BC_FONT5_BITMAP = 1
ELSE
IFDEF BASECONF_VIDEO_TEXT_ATM_640
defc BC_FONT5_BITMAP = 1
ENDIF
ENDIF
IFDEF BC_FONT5_BITMAP
        MODULE bc__font5_draw_bitmap

SECTION code_clib
PUBLIC bc__font5_bitmap_init
PUBLIC bc__font5_bitmap_address
PUBLIC bc__font5_bitmap_masks
PUBLIC bc__font5_bitmap_row
PUBLIC bc__font5_map_page
EXTERN bc__video_map_page_regs
EXTERN _bc_video_cpu_base

; Shared ZX256/ATM640 context, anchored at the saved-IX callback frame:
; x +4, y +6, font +8, code +10, ink +11, paper +12.
; Caller reserves eighteen bytes: -2 glyph, -3 width, -4 height, -5 background,
; -6 shift, -8 bitmap, -10 initial address (ZX) or offset (ATM),
; -12 spill delta, -13 glyph mask,
; -14/-15 clear masks, -16 width+shift, -17 rows remaining, -18 attribute.
; These helpers preserve IX/IY and do not select a video mode.

; A = mode-specific attribute. Initialize character-wide values once.
;
; Prepares the glyph attribute and records how far the glyph extends across
; the destination bytes.
;
; Model:
;
; shift=x&7; span=shift+width; context.attribute=A.
;
; Uses the eighteen-byte persistent context above. AF clobbered; BC/DE/HL and
; IX/IY retained. No bitmap access until the caller maps a page.
bc__font5_bitmap_init:
        ld (ix-18),a
        ld a,(ix+4)
        and 7
        ld (ix-6),a
        add a,(ix-3)
        ld (ix-16),a                 ; a second byte is needed when >=9
        ret

; HL = initial raster offset, BC = delta to a spill byte.
; Retain the offset for the ATM attribute plane and cache the bitmap address.
;
; Records the starting bitmap address and the displacement to a second byte
; when the glyph straddles a boundary.
;
; Model:
;
; initial_offset=HL; spill_delta=BC; bitmap=cpu_base+HL.
;
; Keep offset separately so attributes can be addressed after another page map.
; DE/HL/flags volatile; BC and IX/IY preserved; writes only the named locals.
bc__font5_bitmap_address:
        ld (ix-10),l
        ld (ix-9),h
        ld (ix-12),c
        ld (ix-11),b
        ld de,(_bc_video_cpu_base)
        add hl,de
        ld (ix-8),l
        ld (ix-7),h
        ret

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

; A = surface page. Return Z for ZX_OK, NZ otherwise.
; Tail adapter to the register selector; preserve B/DE/IX/IY, clobber AF/C/HL.
; Call only while the video lease is held.
bc__font5_map_page:
        ld c,a
        jp bc__video_map_page_regs
ENDIF
