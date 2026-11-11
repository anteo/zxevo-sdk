        MODULE xorplot
SECTION code_graphics
PUBLIC _xorplot
PUBLIC _c_xorplot
EXTERN bc__graphics_plot_operation

; Small-C caller-clean x,y. Tail-enter the pixel wrapper with op in A.
_c_xorplot:
_xorplot:
        ld a,2
        jp bc__graphics_plot_operation
