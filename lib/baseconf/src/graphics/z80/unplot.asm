        MODULE unplot
EXTERN bc__graphics_plot_operation
SECTION code_graphics
PUBLIC _unplot
_unplot:
        ld a,1
        jp bc__graphics_plot_operation
