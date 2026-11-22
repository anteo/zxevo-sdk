IFDEF BASECONF_VIDEO_TEXT_ATM_640
        MODULE bc__font5_draw_atm640
INCLUDE "console/font5_bitmap.inc"
SECTION code_clib
PUBLIC bc__font5_draw_atm640
EXTERN bc__font5_draw_return
EXTERN bc__video_packed_pixels_regs
EXTERN bc__video_row_offset_40
EXTERN bc__font5_bitmap_masks
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base

; Paint a glyph in ATM640's alternating bitmap planes. Rotate each source
; byte once, then select its covered bits in each destination byte.
;
; offset = y*40 + (x>>4) + ((x&8) ? 0x2000 : 0);
; field[0..1] = masks_for_span(x&7, width);
; keep[i] = transparent ? 0xff : ~field[i];
; for (r=0; r<height; ++r) {
;     bits = ror8(glyph[r], x&7);
;     for each covered column i:
;         bitmap[i] = (bitmap[i] & keep[i]) | (bits & field[i]);
;     advance one scanline;
; }
; if (opaque) fill the same columns on the attribute page with pack(ink,paper);
;
; Tail entry with an active lease, both pages mapped and an in-bounds glyph
; of width/height 1..8. IX anchors the callback frame. Below its five locals
; are saved IY and the initial plane offset. WIDTH becomes the row counter
; after mask setup; HEIGHT remains available for the attributes.
; DE walks the glyph, HL the bitmap. B/C mask the first and second bytes.
; IY selects the rotation and the opaque/transparent merge. AF/BC/DE/HL
; volatile, IX/IY restored.
bc__font5_draw_atm640:
        push iy
        ld a,(ix+6)
        call bc__video_row_offset_40
        ld a,(ix+4)
        and 0f0h
        or (ix+5)                    ; x < 640: swap nibbles to get x >> 4
        rrca
        rrca
        rrca
        rrca
        ld e,a
        ld d,0
        add hl,de
        bit 3,(ix+4)
        jr z,@plane
        set 5,h
@plane:
        push hl                      ; initial plane offset, also used by attributes
        ld de,(_bc_video_page1_base)
        add hl,de
        push hl                      ; bitmap address across mask setup

        call bc__font5_bitmap_masks
        ld hl,@opaque
        bit 0,(ix+BC_FONT5_BACKGROUND)
        jr z,@rotation
        ld hl,@overlay
@rotation:
        or a
        sbc hl,de                    ; one byte per RRCA at either entry
        push hl
        pop iy
        ld e,(ix+BC_FONT5_SOURCE)
        ld d,(ix+BC_FONT5_SOURCE+1)
        ld a,(ix+BC_FONT5_HEIGHT)
        ld (ix+BC_FONT5_WIDTH),a
        pop hl
@row:
        ld a,(de)
        inc de
        jp (iy)
        ; A suffix of these one-byte rotations moves the spill bits to the
        ; high end of A. B and C select only pixels within the glyph width.
        REPT 7
        rrca
        ENDR
@overlay:
        or a
        jr z,@advance
        push af
        and b
        or (hl)
        ld (hl),a
        pop af
        and c
        jr z,@advance                ; no ink crosses into the other plane
        push hl
        call @next_column
        or (hl)
        jr @store_second

        REPT 7
        rrca
        ENDR
@opaque:
        push af
        xor (hl)
        and b
        xor (hl)                     ; old ^ ((old ^ rotated) & field)
        ld (hl),a
        pop af
        bit 7,c                      ; every nonempty spill includes bit 7
        jr z,@advance
        push hl
        call @next_column
        xor (hl)
        and c
        xor (hl)
@store_second:
        ld (hl),a
        pop hl
@advance:
        ld a,l
        add a,40
        ld l,a
        jr nc,@count
        inc h
@count:
        dec (ix+BC_FONT5_WIDTH)
        jr nz,@row

        pop hl
        pop iy
        bit 0,(ix+BC_FONT5_BACKGROUND)
        jp nz,bc__font5_draw_return
        ld de,(_bc_video_page0_base)
        add hl,de
        ld e,(ix+11)
        ld d,(ix+12)
        call bc__video_packed_pixels_regs
        ld de,40
        bit 7,c
        jr z,@last_column
        push hl
        call @attributes
        pop hl
        call @next_column
@last_column:
        call @attributes
        jp bc__font5_draw_return

; Fill one vertical attribute column. A=color, HL=top address, DE=40.
@attributes:
        ld b,(ix+BC_FONT5_HEIGHT)
@attribute_row:
        ld (hl),a
        add hl,de
        djnz @attribute_row
        ret

; Advance HL by one logical bitmap or attribute byte. The even plane spills
; to the odd plane, the odd plane to the next group of the even plane.
@next_column:
        bit 5,h
        jr nz,@wrap
        set 5,h
        ret
@wrap:
        res 5,h
        inc hl
        ret
ENDIF
