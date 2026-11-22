        MODULE point
EXTERN bc__graphics_read_point
SECTION code_graphics
PUBLIC _point
_point:
        ld a,5
        jp bc__graphics_read_point
