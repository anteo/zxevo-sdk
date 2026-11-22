        MODULE ts_console_draw_packed
INCLUDE "font/z80/zx_font.inc"
SECTION code_clib
IFDEF TSCONF_VIDEO_PACKED
PUBLIC ts_console_draw_packed
IFDEF TSCONF_VIDEO_16C
IFDEF TSCONF_VIDEO_256C
EXTERN ts_draw_config
ENDIF
ENDIF
EXTERN ts_draw_page
EXTERN ts_packed_begin_window
EXTERN ts_packed_end
IFDEF TSCONF_VIDEO_16C
EXTERN ts_packed_address16
ENDIF
IFDEF TSCONF_VIDEO_256C
EXTERN ts_packed_address256
ENDIF
EXTERN zx__font_rows_from_frame

defc TS_GLYPH_WIDTH = -2

; Draw a glyph on a packed surface with one Page3 mapping.
;
; glyph = font_rows(code); begin_window(page); dst = address(x, y);
; for (r=0; r<8; ++r) {
;     emit ink for set bits; emit paper for clear bits only if opaque;
;     dst += mode == 16c ? 256 : 512;
; }
; end();
;
; Tail entry from either SDCC font callback. IX points at saved IX
; (x +4, y +6, font +8, code +10, ink +11, paper +12, background +13), C=width (5 or 8).
; Even X and eight-scanline-aligned Y are in bounds. The glyph fits one page.
; IX-2 holds the width. IY points at the next glyph row. The row count and
; destination start are saved on the stack while emitting pixels.
; AF/BC/DE/HL volatile, IX/IY restored on return.
ts_console_draw_packed:
        push bc
        call zx__font_rows_from_frame
        push iy
        push hl
        pop iy
        ld a,(ts_draw_page)
        ld d,a
        call ts_packed_begin_window
        jp c,@return
        ld l,(ix+4)
        ld h,(ix+5)
        ld e,(ix+6)
        ld d,(ix+7)
IFDEF TSCONF_VIDEO_16C
IFDEF TSCONF_VIDEO_256C
        ld a,(ts_draw_config)
        and 3
        cp 2
        jr z,@indexed
ENDIF

        call ts_packed_address16
        ld a,(ix+11)
        and 0fh
        ld e,a
        ld a,(ix+12)
        and 0fh
        ld d,a
        ld a,8
@row16:
        push af
        push hl
        ld c,(iy+0)
        inc iy
        ld b,(ix+TS_GLYPH_WIDTH)
        srl b
@pair:
        call @left_nibble
        sla c
        jr nc,@right_paper
        or e
        jr @put_pair
@right_paper:
        bit 0,(ix+ZX_TEXT_BACKGROUND_ARG)
        jr nz,@keep_right
        or d
        jr @put_pair
@keep_right:
        ; Replace only the high nibble with the value in A.
        xor (hl)
        and 0f0h
        xor (hl)
@put_pair:
        ld (hl),a
        inc hl
        djnz @pair
        bit 0,(ix+TS_GLYPH_WIDTH)
        jr z,@next16
        ; The fifth pixel occupies the high nibble. Keep its neighbour.
        call @left_nibble
        xor (hl)
        and 0f0h
        xor (hl)
        ld (hl),a
@next16:
        pop hl
        inc h                        ; next scanline is 256 bytes away
        pop af
        dec a
        jr nz,@row16
IFDEF TSCONF_VIDEO_256C
        jr @done
ENDIF
ENDIF

IFDEF TSCONF_VIDEO_256C
@indexed:
        call ts_packed_address256
        ld e,(ix+11)
        ld d,(ix+12)
        ld a,8
@row256:
        push af
        push hl
        ld c,(iy+0)
        inc iy
        ld b,(ix+TS_GLYPH_WIDTH)
@pixel:
        sla c
        ld a,e
        jr c,@put_pixel
        bit 0,(ix+ZX_TEXT_BACKGROUND_ARG)
        jr nz,@advance_pixel
        ld a,d
@put_pixel:
        ld (hl),a
@advance_pixel:
        inc hl
        djnz @pixel
        pop hl
        inc h
        inc h                        ; next scanline is 512 bytes away
        pop af
        dec a
        jr nz,@row256
ENDIF
@done:
        call ts_packed_end
@return:
        pop iy
        ld sp,ix
        pop ix
        ret

; Consume the next glyph bit and return its high nibble, including any old pixel.
IFDEF TSCONF_VIDEO_16C
@left_nibble:
        sla c
        jr c,@left_ink
        bit 0,(ix+ZX_TEXT_BACKGROUND_ARG)
        jr nz,@keep_left
        ld a,d
        jr @shift
@left_ink:
        ld a,e
@shift:
        rlca
        rlca
        rlca
        rlca
        ret
@keep_left:
        ld a,(hl)
        and 0f0h
        ret
ENDIF
ENDIF
