        MODULE bc_text_draw_font
INCLUDE "font/z80/zx_font.inc"
INCLUDE "console/font_flags.inc"
SECTION code_clib
PUBLIC _bc_text_draw_font
EXTERN _bc__font8_draw
EXTERN _bc__text_draw_font
EXTERN _zx__console_text_bg

; SDCC column:8, row:8, text:16, glyphs:16. Preserve IX/IY.
; Build an eight-byte 8x8 descriptor on the stack, independent of active font.
; The common renderer owns bounds, lease handling and string traversal.
;
; Draws a string with caller-supplied eight-by-eight glyph data, using that
; font only for this call.
;
; Model:
;
; if (!glyphs) return INVALID_ARGUMENT;
; font={glyphs,8,8,8,BUILTIN_RENDERER,font8_draw};
; return text_draw_font(column,row,text,&font,UINT16_MAX,text_bg);
;
; The eight-byte descriptor is a persistent stack local below IX; the nine
; outgoing renderer argument bytes are below it and may change. Descriptor
; lifetime covers the complete synchronous draw call; IX/IY preserved, status L.
_bc_text_draw_font:
        push ix
        ld ix,0
        add ix,sp
        ld l,(ix+8)
        ld h,(ix+9)
        ld a,h
        or l
        jr z,@invalid
        ld hl,_bc__font8_draw
        push hl
        ld hl,8+BC_FONT_TEXT_BACKEND*256  ; flags:advance
        push hl
        ld hl,0808h                 ; width=8, height=8
        push hl
        ld l,(ix+8)
        ld h,(ix+9)
        push hl                     ; glyphs; descriptor begins here
        ld a,(_zx__console_text_bg)
        push af
        inc sp                      ; background:8
        ld hl,-1                    ; let the string terminator or row end stop drawing
        push hl
        ld hl,3
        add hl,sp
        push hl
        ld e,(ix+6)
        ld d,(ix+7)
        push de
        ld c,(ix+4)
        ld b,(ix+5)
        push bc
        call _bc__text_draw_font
        jr @return
@invalid:
        ld l,1                      ; ZX_INVALID_ARGUMENT
@return:
        ld sp,ix
        pop ix
        ret
