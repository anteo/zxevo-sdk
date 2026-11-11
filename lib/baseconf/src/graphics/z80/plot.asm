        MODULE plot
SECTION code_graphics
PUBLIC _plot
PUBLIC _c_plot
EXTERN bc__graphics_plot_operation

; Small-C caller-clean x,y. Tail-enter the pixel wrapper with op in A.
_c_plot:
_plot:
        xor a
        jp bc__graphics_plot_operation
