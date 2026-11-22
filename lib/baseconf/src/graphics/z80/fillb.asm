        MODULE fillb
EXTERN bc__graphics_rect_extent_a
SECTION code_graphics
PUBLIC _fillb
_fillb:
        xor a                        ; PIXEL_SET
        jp bc__graphics_rect_extent_a
