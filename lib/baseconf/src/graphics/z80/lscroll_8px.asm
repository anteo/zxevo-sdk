        MODULE lscroll_8px
SECTION code_graphics
PUBLIC _lscroll_8px
EXTERN bc__graphics_scroll_horizontal

; z88dk horizontal scroll. L=pixels, H=right. Preserve IX/IY.
_lscroll_8px:
        ld hl,8
        jp bc__graphics_scroll_horizontal
