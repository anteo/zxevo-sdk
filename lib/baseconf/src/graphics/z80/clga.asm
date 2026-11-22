        MODULE clga
EXTERN bc__graphics_rect_begin
SECTION code_graphics
PUBLIC _clga

; Clear the rectangle between the Small-C caller's inclusive corners.
_clga:
        xor a
        inc a                        ; PIXEL_CLEAR, carry clear
        jp bc__graphics_rect_begin
