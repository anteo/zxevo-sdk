        MODULE rscroll_8px
SECTION code_graphics
PUBLIC _rscroll_8px
EXTERN bc__graphics_scroll_horizontal

; z88dk horizontal scroll. L=pixels, H=right. Preserve IX/IY.
_rscroll_8px:
        ld hl,264
        jp bc__graphics_scroll_horizontal
