        MODULE zx__graphics_rect_a
SECTION code_graphics
PUBLIC zx__graphics_rect_a
IFDEF TSCONF_VIDEO_BITMAP
EXTERN ts_draw_config
IFDEF TSCONF_VIDEO_ZX
EXTERN ts_draw_base
EXTERN zx__bitmap_offset
EXTERN zx__span_masks
ENDIF
IFDEF TSCONF_VIDEO_PACKED
EXTERN ts_draw_page
EXTERN ts_packed_begin_window
EXTERN ts_packed_end
EXTERN zx__ink
EXTERN zx__paper
IFDEF TSCONF_VIDEO_16C
EXTERN ts_packed_address16
ENDIF
IFDEF TSCONF_VIDEO_256C
EXTERN ts_packed_address256
ENDIF
ENDIF
EXTERN zx__clip_extent
EXTERN zx__fill_bytes

defc TS_RECT_X = 4
defc TS_RECT_Y = 6
defc TS_RECT_WIDTH = 8
defc TS_RECT_HEIGHT = 10
defc TS_RECT_MODE = -1
defc TS_RECT_OPERATION = -2
defc TS_RECT_LAST_X = -4
defc TS_RECT_FIRST_X = -6
defc TS_RECT_LAST_Y = -8
defc TS_RECT_ROW = -10
defc TS_RECT_BYTE_DELTA = -12
defc TS_RECT_LAST_MASK = -14
defc TS_RECT_FIRST_MASK = -13
defc TS_RECT_PAINT = -15

; Fill the clipped rectangle with bitmap bits or palette indices by scanline.
;
; if (mode == TEXT || !clip_extents(x,y,width,height)) return;
; paint = zx_bitmap ? (op == SET ? 0xff : 0) : (op == SET ? ink : paper);
; prepare_byte_span(x_first, x_last, mode, paint);
; if (packed) begin(page, mode);
; for (y = first_row; y <= last_row; ++y)
;     fill_span(row_address(x_first,y), byte_delta, paint, edge_masks);
; if (packed) end();
;
; SDCC signed words x/y/width/height, with SET or CLEAR in A. ZX needs its page
; mapped. Packed paths own W3 for the whole rectangle. IX anchors the saved IX
; and the persistent locals above. IY preserved, AF/BC/DE/HL volatile.
zx__graphics_rect_a:
        ld b,a
        ld a,(ts_draw_config)
        and 3
        cp 3                         ; text or unselected
        ret z
        push ix
        ld ix,0
        add ix,sp
        push af
        ld (ix+TS_RECT_OPERATION),b

        ld bc,512
        or a
        jr nz,@clip_x
        ld bc,256
@clip_x:
        ld l,(ix+TS_RECT_X)
        ld h,(ix+TS_RECT_X+1)
        ld e,(ix+TS_RECT_WIDTH)
        ld d,(ix+TS_RECT_WIDTH+1)
        call zx__clip_extent
        jp c,@return
        push de
        push hl

        ld a,(ix+TS_RECT_MODE)
        or a
        jr nz,@clip_y
        ld bc,192
@clip_y:
        ld l,(ix+TS_RECT_Y)
        ld h,(ix+TS_RECT_Y+1)
        ld e,(ix+TS_RECT_HEIGHT)
        ld d,(ix+TS_RECT_HEIGHT+1)
        call zx__clip_extent
        jp c,@return
        push de
        push hl
        push bc
        push bc
        push bc                       ; delta word, mask word, and paint byte

IFDEF TSCONF_VIDEO_ZX
IFDEF TSCONF_VIDEO_PACKED
        ld a,(ix+TS_RECT_MODE)
        or a
        jr nz,@prepare_packed
ENDIF
        ld a,(ix+TS_RECT_FIRST_X)
        ld c,(ix+TS_RECT_LAST_X)
        call zx__span_masks
        ld (ix+TS_RECT_FIRST_MASK),b
        ld (ix+TS_RECT_LAST_MASK),c
        ld a,(ix+TS_RECT_FIRST_X)
        call @zx_byte_column
        ld c,a
        ld a,(ix+TS_RECT_LAST_X)
        call @zx_byte_column
        sub c
        ld (ix+TS_RECT_BYTE_DELTA),a
        ld a,(ix+TS_RECT_OPERATION)
        dec a                         ; SET = ffh, CLEAR = 00h
IFDEF TSCONF_VIDEO_PACKED
        jr @paint_ready
ENDIF
ENDIF

IFDEF TSCONF_VIDEO_PACKED
@prepare_packed:
        ld a,(ix+TS_RECT_MODE)
        ld hl,ts_draw_page
        ld d,(hl)
        push af
        call ts_packed_begin_window
        pop bc                        ; B = saved mode, keep carry from begin
        jp c,@return
        ld a,(ix+TS_RECT_OPERATION)
        ld hl,zx__ink
        or a
        jr z,@packed_paint
        ld hl,zx__paper
@packed_paint:
        ld a,(hl)
        ld (ix+TS_RECT_PAINT),a
        ld a,b
        ld l,(ix+TS_RECT_LAST_X)
        ld h,(ix+TS_RECT_LAST_X+1)
        ld e,(ix+TS_RECT_FIRST_X)
        ld d,(ix+TS_RECT_FIRST_X+1)
IFDEF TSCONF_VIDEO_16C
IFDEF TSCONF_VIDEO_256C
        cp 2
        jr z,@indexed_delta
ENDIF

        ; A left odd pixel keeps the high nibble, a right even pixel the low.
        ld b,0ffh
        bit 0,e
        jr z,@first_mask
        ld b,0fh
@first_mask:
        ld (ix+TS_RECT_FIRST_MASK),b
        ld b,0ffh
        bit 0,l
        jr nz,@last_mask
        ld b,0f0h
@last_mask:
        ld (ix+TS_RECT_LAST_MASK),b
        srl h
        rr l
        srl d
        rr e
        or a
        sbc hl,de
        ld (ix+TS_RECT_BYTE_DELTA),l
        ld a,(ix+TS_RECT_PAINT)
        and 0fh
        ld c,a
        rlca
        rlca
        rlca
        rlca
        or c
IFDEF TSCONF_VIDEO_256C
        jr @paint_ready
ENDIF
ENDIF

IFDEF TSCONF_VIDEO_256C
@indexed_delta:
        or a
        sbc hl,de
        ld (ix+TS_RECT_BYTE_DELTA),l
        ld (ix+TS_RECT_BYTE_DELTA+1),h
        jr @row
ENDIF
ENDIF
@paint_ready:
        ld (ix+TS_RECT_PAINT),a
@row:
        ld l,(ix+TS_RECT_FIRST_X)
        ld h,(ix+TS_RECT_FIRST_X+1)
        ld e,(ix+TS_RECT_ROW)
        ld d,(ix+TS_RECT_ROW+1)
IFDEF TSCONF_VIDEO_ZX
IFDEF TSCONF_VIDEO_PACKED
        ld a,(ix+TS_RECT_MODE)
        or a
        jr nz,@packed_row
ENDIF
        ld c,e
        ld a,l
        call @zx_byte_column
        ld e,a
        ld a,(ts_draw_base)
        ld d,a
        call zx__bitmap_offset
        call @paint_masked
IFDEF TSCONF_VIDEO_PACKED
        jr @next
ENDIF
ENDIF
IFDEF TSCONF_VIDEO_PACKED
@packed_row:
IFDEF TSCONF_VIDEO_16C
IFDEF TSCONF_VIDEO_256C
        ld a,(ix+TS_RECT_MODE)
        cp 2
        jr z,@indexed_row
ENDIF
        call ts_packed_address16
        call @paint_masked
IFDEF TSCONF_VIDEO_256C
        jr @next
ENDIF
ENDIF
IFDEF TSCONF_VIDEO_256C
@indexed_row:
        call ts_packed_address256
        ld c,(ix+TS_RECT_BYTE_DELTA)
        ld b,(ix+TS_RECT_BYTE_DELTA+1)
        inc bc
        ld a,(ix+TS_RECT_PAINT)
        call zx__fill_bytes
ENDIF
ENDIF
@next:
        ld l,(ix+TS_RECT_ROW)
        ld h,(ix+TS_RECT_ROW+1)
        ld e,(ix+TS_RECT_LAST_Y)
        ld d,(ix+TS_RECT_LAST_Y+1)
        or a
        sbc hl,de
        jr z,@done
        add hl,de
        inc hl
        ld (ix+TS_RECT_ROW),l
        ld (ix+TS_RECT_ROW+1),h
        jp @row
@done:
IFDEF TSCONF_VIDEO_PACKED
IFDEF TSCONF_VIDEO_ZX
        ld a,(ix+TS_RECT_MODE)
        or a
        call nz,ts_packed_end
ELSE
        call ts_packed_end
ENDIF
ENDIF
@return:
        ld sp,ix
        pop ix
        ret

IFDEF TSCONF_VIDEO_ZX
@zx_byte_column:
        rrca
        rrca
        rrca
        and 31
        ret
ENDIF

IFDEF TSCONF_VIDEO_MASKED
; Apply the prepared masks at the ends and fill the whole bytes between them.
;
; if (first == last) replace_bits(first, first_mask & last_mask, paint);
; else {
;     replace_bits(first, first_mask, paint); replace_bits(last, last_mask, paint);
;     fill(first + 1, last - first - 1, paint);
; }
;
; HL=first byte, IX=rectangle frame. A masked span is at most 256 bytes.
; Preserve IX/IY, clobber AF/BC/DE/HL. Edge writes preserve HL/BC/E.
@paint_masked:
        ld c,(ix+TS_RECT_BYTE_DELTA)
        ld b,0
        ld e,(ix+TS_RECT_PAINT)
        ld a,c
        or a
        ld a,(ix+TS_RECT_FIRST_MASK)
        jr nz,@separate
        and (ix+TS_RECT_LAST_MASK)
        jr @edge
@separate:
        call @edge
        inc hl
        dec bc
        push hl
        add hl,bc
        ld a,(ix+TS_RECT_LAST_MASK)
        call @edge
        pop hl
        ld a,e
        jp zx__fill_bytes
@edge:
        ld d,a
        ld a,(hl)
        xor e
        and d
        xor (hl)
        ld (hl),a
        ret
ENDIF
ELSE
zx__graphics_rect_a:
        ret
ENDIF
