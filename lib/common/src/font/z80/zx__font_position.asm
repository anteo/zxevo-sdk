        MODULE zx__font_position
INCLUDE "font/z80/zx_font.inc"
SECTION code_clib
PUBLIC zx__font_position

; HL = font, A = column, C = row. IX anchors the caller's draw context:
; font -2/-1, x -4/-3, y -6/-5, ink -8, paper -7, character -9.
; Set font/x/y, preserving ink/paper/character and IX/IY. No CRT multiply.
;
; Converts a console cell position into pixel coordinates using the font
; advance and an eight-pixel row height.
;
; Model:
;
; context.font=font; context.x=column*font->advance; context.y=row*8;
;
; The eight-bit shift/add product fits 16 bits. Width/height checks belong
; to the caller; AF/BC/DE/HL volatile, IX/IY and the other context fields survive.
zx__font_position:
        ld (ix-2),l
        ld (ix-1),h
        ld e,a
        ld l,c
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ld (ix-6),l
        ld (ix-5),h
        ld l,(ix-2)
        ld h,(ix-1)
        ld bc,ZX_FONT_ADVANCE_OFFSET
        add hl,bc
        ld c,(hl)
        ld h,e
        ld l,0
        ld e,c
        ld d,0
        ld b,8
@multiply:
        add hl,hl
        jr nc,@next_bit
        add hl,de
@next_bit:
        djnz @multiply
        ld (ix-4),l
        ld (ix-3),h
        ret
