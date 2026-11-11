        MODULE bc__console_graphics_cell_write
INCLUDE "font/z80/zx_font.inc"

SECTION code_clib
PUBLIC _bc__console_graphics_cell_write
EXTERN _zx_console_get_font
EXTERN zx__ink
EXTERN zx__paper
EXTERN generic_console_flags
EXTERN zx__font_position
EXTERN zx__font_call
EXTERN _zx__console_text_bg

; SDCC caller-clean ABI: column:8 at SP+2, row:8 at SP+3, character:8 at SP+4.
; zx_font_t: glyphs +0, width +2, height +3, advance +4, flags +5, draw +6.
; Draw callback: x, y, font, glyph, ink, paper, background. Preserve IX/IY.
;
; Draws one bitmap console character using the active font and console
; colors, including inverse video.
;
; Model:
;
; font=get_font(); if (!font || !font->draw) return;
; if (inverse) swap(ink,paper); if (character<32 || character>127) character='?';
; font->draw(column*font->advance,row*8,font,character,ink,paper,text_bg);
;
; Caller holds the active graphics lease and checks coordinates. AF/BC/DE/HL
; volatile; IX/IY preserved. The shared nine-byte context below IX stores
; font, x/y, ink/paper and glyph. zx__font_call supplies separate outgoing bytes.
_bc__console_graphics_cell_write:
        push ix
        ld ix,0
        add ix,sp
        ld hl,-9
        add hl,sp
        ld sp,hl
        call _zx_console_get_font
        ld a,h
        or l
        jr z,@done
        push hl
        ld de,ZX_FONT_DRAW_OFFSET
        add hl,de
        ld a,(hl)
        inc hl
        or (hl)
        pop hl
        jr z,@done
        ld a,(ix+4)
        ld c,(ix+5)
        call zx__font_position

        ld a,(zx__ink)
        ld c,a
        ld a,(zx__paper)
        ld b,a
        ld a,(generic_console_flags)
        rlca
        jr nc,@colors
        ld a,b
        ld b,c
        ld c,a
@colors:
        ld (ix-8),c
        ld (ix-7),b
        ld a,(ix+6)
        sub 32
        cp 96
        jr c,@glyph
        ld a,'?'-32
@glyph:
        add a,32
        ld (ix-9),a
        ld a,(_zx__console_text_bg)
        call zx__font_call
@done:
        ld sp,ix
        pop ix
        ret
