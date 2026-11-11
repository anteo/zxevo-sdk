        MODULE scrollup_1px
SECTION code_graphics
PUBLIC _scrollup_1px
EXTERN bc__graphics_scroll_up

; z88dk upward scroll. A=rows. Preserve IX/IY.
_scrollup_1px:
        ld a,1
        jp bc__graphics_scroll_up
