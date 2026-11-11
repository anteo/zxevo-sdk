        MODULE scrollup_4px
SECTION code_graphics
PUBLIC _scrollup_4px
EXTERN bc__graphics_scroll_up

; z88dk upward scroll. A=rows. Preserve IX/IY.
_scrollup_4px:
        ld a,4
        jp bc__graphics_scroll_up
