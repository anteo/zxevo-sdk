IFDEF BASECONF_VIDEO_TEXT_ATM_320
        MODULE bc__font5_draw_atm320

SECTION code_clib
PUBLIC bc__font5_draw_atm320
EXTERN bc__font5_draw_pixels
EXTERN bc__font5_draw_return
EXTERN bc__video_pixel_linear_offset
EXTERN bc__video_packed_pixels_regs
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base

defc BC_ATM_GLYPH_PAIR0 = -7
defc BC_ATM_GLYPH_PAIR1 = -9
defc BC_ATM_GLYPH_PAIR2 = -11
defc BC_ATM_GLYPH_LEFT_INK = -12
defc BC_ATM_GLYPH_RIGHT_INK = -13
defc BC_ATM_GLYPH_LEFT_PAPER = -14
defc BC_ATM_GLYPH_RIGHT_PAPER = -15

; Paint an ATM 320 glyph using one byte update per packed pixel pair.
;
; if (width != 5 || height != 8 || (x & 1)) return draw_pixels();
; for (i = 0; i < 3; ++i) pair[i] = packed_address(x + i*2, y);
; for (row = 0; row < 8; ++row) {
;     for (i = 0; i < 5; ++i)
;         if (glyph[row] & (0x80 >> i)) set_field(pair[i/2], i&1, ink);
;         else if (!transparent) set_field(pair[i/2], i&1, paper);
;     for (i = 0; i < 3; ++i) pair[i] += 40;
; }
;
; Enter from the font dispatcher with an active lease and in-bounds glyph.
; IX anchors the callback frame, SP=IX-5. Add three pair pointers and four
; prepacked color fields below the shared glyph/size/background locals.
; Return through the shared epilogue. AF/BC/DE/HL volatile, IX/IY preserved.
bc__font5_draw_atm320:
        ld a,(ix-3)
        cp 5
        jp nz,bc__font5_draw_pixels
        ld a,(ix-4)
        cp 8
        jp nz,bc__font5_draw_pixels
        bit 0,(ix+4)
        jp nz,bc__font5_draw_pixels

        ld hl,-10
        add hl,sp
        ld sp,hl
        ld l,(ix+4)
        ld h,(ix+5)
        ld e,(ix+6)
        ld d,(ix+7)
        ld b,3
        call bc__video_pixel_linear_offset
        and 6
        ld b,a
        ex de,hl
        call @pair_address
        ld (ix+BC_ATM_GLYPH_PAIR0),l
        ld (ix+BC_ATM_GLYPH_PAIR0+1),h
        call @next_pair
        ld (ix+BC_ATM_GLYPH_PAIR1),l
        ld (ix+BC_ATM_GLYPH_PAIR1+1),h
        call @next_pair
        ld (ix+BC_ATM_GLYPH_PAIR2),l
        ld (ix+BC_ATM_GLYPH_PAIR2+1),h

        ld e,(ix+11)
        ld d,e
        call bc__video_packed_pixels_regs
        ld d,a
        and 47h
        ld (ix+BC_ATM_GLYPH_LEFT_INK),a
        ld a,d
        and 0b8h
        ld (ix+BC_ATM_GLYPH_RIGHT_INK),a
        ld e,(ix+12)
        ld d,e
        call bc__video_packed_pixels_regs
        ld d,a
        and 47h
        ld (ix+BC_ATM_GLYPH_LEFT_PAPER),a
        ld a,d
        and 0b8h
        ld (ix+BC_ATM_GLYPH_RIGHT_PAPER),a

        ld b,8
@row:
        ld l,(ix-2)
        ld h,(ix-1)
        ld c,(hl)
        inc hl
        ld (ix-2),l
        ld (ix-1),h
        ld de,40

        ld l,(ix+BC_ATM_GLYPH_PAIR0)
        ld h,(ix+BC_ATM_GLYPH_PAIR0+1)
        call @put_pair
        add hl,de
        ld (ix+BC_ATM_GLYPH_PAIR0),l
        ld (ix+BC_ATM_GLYPH_PAIR0+1),h
        ld l,(ix+BC_ATM_GLYPH_PAIR1)
        ld h,(ix+BC_ATM_GLYPH_PAIR1+1)
        call @put_pair
        add hl,de
        ld (ix+BC_ATM_GLYPH_PAIR1),l
        ld (ix+BC_ATM_GLYPH_PAIR1+1),h
        ld l,(ix+BC_ATM_GLYPH_PAIR2)
        ld h,(ix+BC_ATM_GLYPH_PAIR2+1)
        call @left
        ld (hl),a                   ; the sixth pixel is outside the glyph
        add hl,de
        ld (ix+BC_ATM_GLYPH_PAIR2),l
        ld (ix+BC_ATM_GLYPH_PAIR2+1),h
        djnz @row
        jp bc__font5_draw_return

; HL points at the destination byte. Consume glyph bits from C, MSB first.
; Each merge masks in the untouched physical field before applying color.
; Preserve B/DE/HL. The left-only entry returns A without storing.
@put_pair:
        call @left
        sla c
        jr c,@right_ink
        bit 0,(ix-5)
        jr nz,@store
        and 47h
        or (ix+BC_ATM_GLYPH_RIGHT_PAPER)
        jr @store
@right_ink:
        and 47h
        or (ix+BC_ATM_GLYPH_RIGHT_INK)
@store:
        ld (hl),a
        ret
@left:
        ld a,(hl)
        sla c
        jr c,@left_ink
        bit 0,(ix-5)
        ret nz
        and 0b8h
        or (ix+BC_ATM_GLYPH_LEFT_PAPER)
        ret
@left_ink:
        and 0b8h
        or (ix+BC_ATM_GLYPH_LEFT_INK)
        ret

; B = x & 6, DE = y*40 + (x>>3). Advance to the next byte only when
; crossing an eight-pixel group. Within a group, x bit 1 selects the
; mapped page and x bit 2 selects its second 8 KiB plane. Return HL.
@next_pair:
        ld a,b
        add a,2
        and 6
        ld b,a
        jr nz,@pair_address
        inc de
@pair_address:
        ld hl,(_bc_video_page0_base)
        bit 1,b
        jr z,@plane
        ld hl,(_bc_video_page1_base)
@plane:
        add hl,de
        bit 2,b
        ret z
        set 5,h
        ret
ENDIF
