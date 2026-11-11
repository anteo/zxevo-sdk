        MODULE scrollup_6px
SECTION code_graphics
PUBLIC _scrollup_6px
EXTERN bc__graphics_scroll_up

; z88dk upward scroll. A=rows. Preserve IX/IY.
_scrollup_6px:
        ld a,6
        jp bc__graphics_scroll_up
