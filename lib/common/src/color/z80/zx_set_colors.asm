        MODULE zx_set_colors
SECTION code_clib
PUBLIC _zx_set_colors
EXTERN zx__ink
EXTERN _zx_set_border_color

; Store the adjacent ink/paper bytes and set the target's hardware border.
; SDCC border/ink/paper at SP+2/+3/+4. Fastcall L=border for the tail call.
; AF/BC/DE/HL volatile, IX/IY preserved. No palette or geometry update.
_zx_set_colors:
        ld hl,2
        add hl,sp
        ld a,(hl)
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld (zx__ink),de
        ld l,a
        jp _zx_set_border_color
