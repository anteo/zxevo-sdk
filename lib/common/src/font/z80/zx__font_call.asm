        MODULE zx__font_call
INCLUDE "font/z80/zx_font.inc"
SECTION code_clib
PUBLIC zx__font_call

; IX draw context: font -2/-1, x -4/-3, y -6/-5,
; ink -8, paper -7, character -9. A=background mode. Preserve IX/IY.
; Copy ten outgoing bytes on each call: a C callback may alter its arguments.
;
; Invokes the selected font callback to draw the character stored in the
; current draw context.
;
; Model:
;
; font->draw(x,y,font,character,ink,paper,background);
;
; The nine-byte IX context above remains persistent. Rebuild the ten
; outgoing callback bytes on every call; callbacks may overwrite those bytes.
; AF/BC/DE/HL volatile; callback must obey the C IX/IY preservation contract.
zx__font_call:
        push af
        inc sp                       ; background:8
        ld l,(ix-8)
        ld h,(ix-7)
        push hl                      ; ink:8, paper:8
        ld a,(ix-9)
        push af
        inc sp                       ; character:8
        ld l,(ix-2)
        ld h,(ix-1)
        push hl                      ; font:16
        ld l,(ix-6)
        ld h,(ix-5)
        push hl                      ; y:16
        ld l,(ix-4)
        ld h,(ix-3)
        push hl                      ; x:16
        ld l,(ix-2)
        ld h,(ix-1)
        ld de,ZX_FONT_DRAW_OFFSET
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ex de,hl
        call @draw
        pop bc
        pop bc
        pop bc
        pop bc
        pop bc
        ret
@draw:
        jp (hl)
