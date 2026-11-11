        MODULE drawb
SECTION code_graphics
PUBLIC _drawb
EXTERN bc__graphics_box

; Small-C caller-clean x,y,width,height. Pass the fixed operation in A.
_drawb:
        xor a
        jp bc__graphics_box
