        MODULE xorplot
EXTERN bc__graphics_plot_operation
SECTION code_graphics
PUBLIC _xorplot
_xorplot:
        ld a,2
        jp bc__graphics_plot_operation
