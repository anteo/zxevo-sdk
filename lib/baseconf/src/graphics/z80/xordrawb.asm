        MODULE xordrawb
SECTION code_graphics
PUBLIC _xordrawb
EXTERN bc__graphics_box

; Small-C caller-clean x,y,width,height. Pass the fixed operation in A.
_xordrawb:
        ld a,2
        jp bc__graphics_box
