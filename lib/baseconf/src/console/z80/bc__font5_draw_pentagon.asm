IFDEF BASECONF_VIDEO_TEXT_PENTAGON_256
        MODULE bc__font5_draw_pentagon
INCLUDE "console/font5_bitmap.inc"

SECTION code_clib
PUBLIC bc__font5_draw_pentagon
EXTERN bc__font5_draw_pixels
EXTERN bc__font5_draw_return
EXTERN bc__font5_packed_colors
EXTERN zx__bitmap_offset
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base
EXTERN _bc_video_operation_depth

; Draw a narrow glyph across three packed pixel pairs on the mapped Pentagon
; screen. An opaque row replaces both complete pairs. A transparent row
; changes only ink pixels. Both leave the sixth pixel intact.
;
; if (!lease) return;
; if (width != 5 || height != 8 || (x & 1) || (y & 7)) return draw_pixels();
; dst[i] = packed_address(x + 2*i, y), i = 0..2;
; for each of the eight glyph rows {
;     paint_pair(dst[0], bits[7:6]); paint_pair(dst[1], bits[5:4]);
;     if (opaque || bit[3]) replace_left(dst[2], bit[3] ? ink : paper);
;     advance each destination by 256;
; }
;
; Tail entry with an in-bounds glyph and the dispatcher's five-byte IX frame.
; Two local words at IX-9..-6 hold opaque colors (II stays in B). Saved IY
; lies below them, followed by one word holding the middle destination.
; HL/DE hold the first/last destination, IY advances through glyph bytes.
; AF/BC/DE/HL volatile, IX/IY restored on return. No page selection changes.
bc__font5_draw_pentagon:
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

        call bc__font5_packed_colors
        push bc
        push hl
        push iy
        ld l,(ix+BC_FONT5_SOURCE)
        ld h,(ix+BC_FONT5_SOURCE+1)
        push hl
        pop iy

        ld a,(ix+4)
        rrca
        rrca
        rrca
        and 31
        ld e,a
        ld d,0
        ld c,(ix+6)
        call zx__bitmap_offset
        ; HL/DE start on opposite pages at the same ZX raster offset.
        ; Pair phases 0,2 begin on page0 and phases 1,3 on page1.
        ld a,(_bc_video_page0_base+1)
        or h
        ld d,a
        ld e,l
        ld a,(_bc_video_page1_base+1)
        or h
        ld h,a
        bit 1,(ix+4)
        jr nz,@pages
        ex de,hl
@pages:
        bit 2,(ix+4)
        jr z,@first_pair
        set 5,h
        set 5,d
@first_pair:
        ; Pair 2 is on the first pair's page, on the opposite 8 KiB plane.
        ; A transition from the upper plane wraps into the next byte column.
        ld a,h
        xor 20h
        ld b,a
        ld c,l
        bit 5,h
        jr z,@middle_pair
        inc c
@middle_pair:
        ; For an odd starting phase, the middle pair has already crossed
        ; the plane boundary and shares pair 2's byte column.
        bit 1,(ix+4)
        jr z,@addresses_ready
        ld a,d
        xor 20h
        ld d,a
        ld e,c
@addresses_ready:
        push de                      ; EX (SP),HL alternates first and middle
        ld d,b
        ld e,c                       ; DE = last pair
        ld b,(ix+BC_FONT5_INK_INK)
@row:
        ld c,(iy+0)
        inc iy
        bit 0,(ix+BC_FONT5_BACKGROUND)
        jr nz,@overlay
        call @opaque_pair
        ld (hl),a
        ex (sp),hl
        call @opaque_pair
        ld (hl),a
        sla c
        ld a,(ix+BC_FONT5_PAPER_PAPER)
        jr nc,@last
        jr @last_ink
@overlay:
        ld a,c
        and 0f8h
        jr nz,@paint_overlay
        ex (sp),hl                   ; same pointer order as a painted row
        jr @advance
@paint_overlay:
        call @overlay_pair
        ex (sp),hl
        call @overlay_pair
        sla c
        jr nc,@advance
@last_ink:
        ld a,b
@last:
        ex de,hl
        xor (hl)
        and 47h                      ; replace left field, keep the neighbour
        xor (hl)
        ld (hl),a
        ex de,hl
@advance:
        inc h
        ex (sp),hl
        inc h
        inc d
        ld a,h
        and 7                        ; aligned first raster: wraps after row eight
        jr nz,@row
        pop hl
        pop iy
        jp bc__font5_draw_return

; Consume two high bits of C. Return the opaque pair in A.
@opaque_pair:
        sla c
        jr c,@left_ink
        sla c
        ld a,(ix+BC_FONT5_PAPER_PAPER)
        ret nc
        ld a,(ix+BC_FONT5_PAPER_INK)
        ret
@left_ink:
        sla c
        ld a,b
        ret c
        ld a,(ix+BC_FONT5_INK_PAPER)
        ret

; Consume two high bits of C. Skip 00, store ink for 11, and blend only
; the left (47h) or right (B8h) field for 10 or 01 respectively.
@overlay_pair:
        sla c
        jr c,@overlay_left
        sla c
        ret nc
        ld a,b
        xor (hl)
        and 0b8h
        jr @merge
@overlay_left:
        sla c
        ld a,b
        jr c,@store
        xor (hl)
        and 47h
@merge:
        xor (hl)
@store:
        ld (hl),a
        ret
ENDIF
