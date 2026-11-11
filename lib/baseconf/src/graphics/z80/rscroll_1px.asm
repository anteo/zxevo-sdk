        MODULE rscroll_1px
SECTION code_graphics
PUBLIC _rscroll_1px
EXTERN bc__graphics_scroll_horizontal

; z88dk horizontal scroll. L=pixels, H=right. Preserve IX/IY.
_rscroll_1px:
        ld hl,257
        jp bc__graphics_scroll_horizontal
