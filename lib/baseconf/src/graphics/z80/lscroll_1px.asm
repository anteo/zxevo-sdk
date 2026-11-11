        MODULE lscroll_1px
SECTION code_graphics
PUBLIC _lscroll_1px
EXTERN bc__graphics_scroll_horizontal

; z88dk horizontal scroll. L=pixels, H=right. Preserve IX/IY.
_lscroll_1px:
        ld hl,1
        jp bc__graphics_scroll_horizontal
