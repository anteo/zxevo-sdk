        MODULE rscroll_2px
SECTION code_graphics
PUBLIC _rscroll_2px
EXTERN bc__graphics_scroll_horizontal

; z88dk horizontal scroll. L=pixels, H=right. Preserve IX/IY.
_rscroll_2px:
        ld hl,258
        jp bc__graphics_scroll_horizontal
