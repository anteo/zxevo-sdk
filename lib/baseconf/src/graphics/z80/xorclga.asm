        MODULE xorclga
EXTERN bc__graphics_rect_begin
SECTION code_graphics
PUBLIC _xorclga
_xorclga:
        ld a,2                       ; PIXEL_XOR
        or a
        jp bc__graphics_rect_begin
