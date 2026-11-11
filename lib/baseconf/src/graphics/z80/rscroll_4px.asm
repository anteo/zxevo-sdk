        MODULE rscroll_4px
SECTION code_graphics
PUBLIC _rscroll_4px
EXTERN bc__graphics_scroll_horizontal

; z88dk horizontal scroll. L=pixels, H=right. Preserve IX/IY.
_rscroll_4px:
        ld hl,260
        jp bc__graphics_scroll_horizontal
