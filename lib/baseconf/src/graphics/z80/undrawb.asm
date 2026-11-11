        MODULE undrawb
SECTION code_graphics
PUBLIC _undrawb
EXTERN bc__graphics_box

; Small-C caller-clean x,y,width,height. Pass the fixed operation in A.
_undrawb:
        ld a,1
        jp bc__graphics_box
