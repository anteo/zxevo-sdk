        MODULE bc__font8_draw
INCLUDE "font/z80/zx_font.inc"

SECTION code_clib
PUBLIC _bc__font8_draw
IFDEF BASECONF_VIDEO_TEXT_GRAPHICS
EXTERN zx__font_rows_from_frame
EXTERN bc__video_draw_glyph_regs
ENDIF

; SDCC callback: x:16, y:16, font:16, code:8, ink:8, paper:8, background:8.
; After saving IX: x +4, y +6, font +8, code +10, ink +11, paper +12, background +13.
; Font8 draws an 8x8 cell at floor(x/8), floor(y/8), as before.
; The shared glyph backend handles colors, lease checks and mode selection.
; Preserve IX/IY; no request, outgoing stack arguments or local scratch.
;
; Draws an eight-by-eight glyph in the character cell containing the supplied
; pixel coordinates.
;
; Model:
;
; draw_glyph(x>>3,y>>3,rows_for_code(font,code),ink,paper,background);
;
; Callback requires a valid font descriptor and an in-bounds cell in an active
; video operation. AF/BC/DE/HL volatile; IX/IY preserved. No pixel fallback or
; font-specific row buffer is retained by this adapter.
_bc__font8_draw:
IFDEF BASECONF_VIDEO_TEXT_GRAPHICS
        push ix
        ld ix,0
        add ix,sp
        call zx__font_rows_from_frame      ; HL = glyph, retained during conversion
        ld a,(ix+5)
        ld c,(ix+4)
        srl a
        rr c
        srl a
        rr c
        srl a
        rr c                         ; C = (uint8_t)(x/8)
        ld a,(ix+7)
        ld b,(ix+6)
        srl a
        rr b
        srl a
        rr b
        srl a
        rr b                         ; B = (uint8_t)(y/8)
        ld e,(ix+11)
        ld d,(ix+12)
        res 7,d                      ; paper uses bits 0..3, bit 7 marks overlay
        bit 0,(ix+ZX_TEXT_BACKGROUND_ARG)
        jr z,@draw
        set 7,d
@draw:
        pop ix
        jp bc__video_draw_glyph_regs
ELSE
        ret
ENDIF
