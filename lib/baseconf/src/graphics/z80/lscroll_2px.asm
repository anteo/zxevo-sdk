        MODULE lscroll_2px
SECTION code_graphics
PUBLIC _lscroll_2px
EXTERN bc__graphics_scroll_horizontal

; z88dk horizontal scroll. L=pixels, H=right. Preserve IX/IY.
_lscroll_2px:
        ld hl,2
        jp bc__graphics_scroll_horizontal
