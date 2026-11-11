        MODULE lscroll_4px
SECTION code_graphics
PUBLIC _lscroll_4px
EXTERN bc__graphics_scroll_horizontal

; z88dk horizontal scroll. L=pixels, H=right. Preserve IX/IY.
_lscroll_4px:
        ld hl,4
        jp bc__graphics_scroll_horizontal
