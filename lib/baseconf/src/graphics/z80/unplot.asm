        MODULE unplot
SECTION code_graphics
PUBLIC _unplot
PUBLIC _c_unplot
EXTERN bc__graphics_plot_operation

; Small-C caller-clean x,y. Tail-enter the pixel wrapper with op in A.
_c_unplot:
_unplot:
        ld a,1
        jp bc__graphics_plot_operation
