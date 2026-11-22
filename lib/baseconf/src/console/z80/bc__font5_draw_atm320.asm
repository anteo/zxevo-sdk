IFDEF BASECONF_VIDEO_TEXT_ATM_320
        MODULE bc__font5_draw_atm320
INCLUDE "console/font5_bitmap.inc"

SECTION code_clib
PUBLIC bc__font5_draw_atm320
EXTERN bc__font5_draw_pixels
EXTERN bc__font5_draw_return
EXTERN bc__video_row_offset_40
EXTERN bc__font5_packed_colors
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base

; Paint five pixels across three packed pairs. The relative addresses of
; those pairs stay constant for all eight rows, including page/plane wraps.
;
; if (width != 5 || height != 8 || (x & 1)) return draw_pixels();
; first, middle, last = addresses(x, x+2, x+4, y);
; to_middle = middle - first; to_last = last - middle;
; for (row = 0; row < 8; ++row, first += 40) {
;     bits = glyph[row];
;     if (transparent && !(bits & 0xf8)) continue;
;     paint_pair(first, bits >> 6);
;     paint_pair(first + to_middle, (bits >> 4) & 3);
;     if (!transparent || (bits & 8))
;         replace_left(first + to_middle + to_last, (bits & 8) ? ink : paper);
; }
;
; Tail entry from the dispatcher with a video lease, mapped split pages and
; an in-bounds glyph. IX anchors the five-byte callback frame. Four packed
; colors occupy IX-9..-6, with saved IY below. HL is the row's first byte,
; DE and BC are the two successive address differences, IY the glyph cursor.
; AF/BC/DE/HL volatile, IX/IY restored. No page changes.
bc__font5_draw_atm320:
        ld a,(ix+BC_FONT5_WIDTH)
        cp 5
        jp nz,bc__font5_draw_pixels
        ld a,(ix+BC_FONT5_HEIGHT)
        cp 8
        jp nz,bc__font5_draw_pixels
        bit 0,(ix+4)
        jp nz,bc__font5_draw_pixels

        call bc__font5_packed_colors
        push bc
        push hl
        push iy
        ld l,(ix+BC_FONT5_SOURCE)
        ld h,(ix+BC_FONT5_SOURCE+1)
        push hl
        pop iy

        ld a,(ix+6)
        call bc__video_row_offset_40
        ld a,(ix+5)
        rrca                         ; x is nine bits on the 320-pixel screen
        ld a,(ix+4)
        rra
        srl a
        srl a
        ld e,a
        ld d,0
        add hl,de
        ; Pair phases are P0, P1, P0+0x2000, P1+0x2000. P0 -> P1
        ; always adds the page distance. P1 -> P0 crosses planes, and
        ; from the upper plane it also advances one byte column.
        ld a,(_bc_video_page0_base+1)
        ld d,a
        ld a,(_bc_video_page1_base+1)
        sub d
        ld b,a
        ld c,0                       ; BC = page1 - page0
        ld a,h
        add a,d
        ld h,a                       ; page0 + y*40 + (x>>3)
        ld a,20h
        sub b
        ld d,a
        ld e,c                       ; DE = page0 + 0x2000 - page1
        bit 2,(ix+4)
        jr z,@plane_ready
        set 5,h
        sub 40h
        ld d,a
        inc e                        ; upper -> lower: -0x2000 and +1 column
@plane_ready:
        bit 1,(ix+4)
        jr z,@page0
        add hl,bc                    ; page1 first: DE then BC
        jr @row
@page0:
        push de                      ; page0 first: swap the two increments
        push bc
        pop de
        pop bc

@row:
        ld a,(iy+0)
        inc iy
        and 0f8h
        jr z,@empty_row
        push hl
        push bc                      ; borrow B for the raster and C for ink
        ld c,(ix+BC_FONT5_INK_INK)
        bit 0,(ix+BC_FONT5_BACKGROUND)
        jr nz,@overlay
        call @opaque_pair
        add hl,de
        call @opaque_pair
        add a,a
        ld a,(ix+BC_FONT5_PAPER_PAPER)
        jr nc,@last
        jr @last_ink
@overlay:
        call @overlay_pair
        add hl,de
        call @overlay_pair
        add a,a
        jr c,@last_ink
        pop bc
        jr @advance
@empty_row:
        bit 0,(ix+BC_FONT5_BACKGROUND)
        jr nz,@next_row
        push hl
        ld a,(ix+BC_FONT5_PAPER_PAPER)
        ld (hl),a
        add hl,de
        ld (hl),a
        jr @last_field
@last_ink:
        ld a,c
@last:
        pop bc
@last_field:
        add hl,bc
        xor (hl)
        and 47h                      ; replace left field, preserve pixel six
        xor (hl)
        ld (hl),a
@advance:
        pop hl
@next_row:
        ld a,l
        add a,40
        ld l,a
        jr nc,@count
        inc h
@count:
        dec (ix+BC_FONT5_HEIGHT)
        jr nz,@row
        pop iy
        jp bc__font5_draw_return

; Consume two high bits of A, write the selected opaque pair and return
; the remaining glyph bits in A. C holds ink/ink, B is scratch.
@opaque_pair:
        add a,a
        jr c,@left_ink
        add a,a
        ld b,(ix+BC_FONT5_PAPER_PAPER)
        jr nc,@opaque_store
        ld b,(ix+BC_FONT5_PAPER_INK)
        jr @opaque_store
@left_ink:
        add a,a
        ld b,c
        jr c,@opaque_store
        ld b,(ix+BC_FONT5_INK_PAPER)
@opaque_store:
        ld (hl),b
        ret

; Consume two bits as above. A 00 pair costs no screen access, 11 replaces
; the byte, and mixed pairs update only the selected field.
@overlay_pair:
        add a,a
        jr c,@overlay_left
        add a,a
        ret nc
        ld b,a
        ld a,c
        xor (hl)
        and 0b8h
        jr @merge
@overlay_left:
        add a,a
        jr nc,@only_left
        ld (hl),c
        ret
@only_left:
        ld b,a
        ld a,c
        xor (hl)
        and 47h
@merge:
        xor (hl)
        ld (hl),a
        ld a,b
        ret

ENDIF
