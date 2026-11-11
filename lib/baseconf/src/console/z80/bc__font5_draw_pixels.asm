IFDEF BASECONF_VIDEO_TEXT_ZX_MULTICOLOR
defc BC_FONT5_PIXELS = 1
ELSE
IFDEF BASECONF_VIDEO_TEXT_PACKED
defc BC_FONT5_PIXELS = 1
ENDIF
ENDIF
IFDEF BC_FONT5_PIXELS
        MODULE bc__font5_draw_pixels

SECTION code_clib
PUBLIC bc__font5_draw_pixels
EXTERN bc__font5_draw_return
EXTERN bc__video_pixel_regs

; Shared multicolor/Pentagon/ATM320 fallback. Tail entry with IX anchored at
; the callback frame, SP=IX-5 and glyph/width/height/background initialized.
; Eight temporary bytes: glyph -2, width -3, height -4, background -5,
; bits -6, columns -7, rows -8.
; Preserve IX/IY on final return; no static scratch.
;
; Draws a glyph one pixel at a time in modes that use the shared pixel
; renderer.
;
; Model:
;
; for (row=0; row<height; ++row) for (col=0; col<width; ++col) {
;     set=rows[row] & (0x80>>col);
;     if (set || opaque) pixel(x+col,y+row,SET_COLOR,set?ink:paper);
; }
;
; Requires the dispatcher context, an active lease and an in-bounds glyph.
; AF/BC/DE/HL volatile. Pass the pixel arguments in registers. Save the
; computed X briefly while computing Y.
bc__font5_draw_pixels:
        push hl
        dec sp
        ld a,(ix-4)
        ld (ix-8),a
@row:
        ld l,(ix-2)
        ld h,(ix-1)
        ld a,(hl)
        ld (ix-6),a
        inc hl
        ld (ix-2),l
        ld (ix-1),h
        ld a,(ix-3)
        ld (ix-7),a
@column:
        ld a,(ix-6)
        add a,a
        ld (ix-6),a
        jr c,@ink
        bit 0,(ix-5)
        jr nz,@next
        ld a,(ix+12)
        jr @draw
@ink:
        ld a,(ix+11)
@draw:
        ld b,a
        ld a,(ix-3)
        sub (ix-7)
        ld e,a
        ld d,0
        ld l,(ix+4)
        ld h,(ix+5)
        add hl,de
        push hl
        ld a,(ix-4)
        sub (ix-8)
        ld e,a
        ld l,(ix+6)
        ld h,(ix+7)
        add hl,de
        ex de,hl
        pop hl
        ld c,4                       ; COLOR
        call bc__video_pixel_regs
@next:
        dec (ix-7)
        jr nz,@column
        dec (ix-8)
        jr nz,@row
        jp bc__font5_draw_return
ENDIF
