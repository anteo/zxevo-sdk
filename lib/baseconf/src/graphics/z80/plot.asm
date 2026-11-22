        MODULE plot
EXTERN bc__graphics_plot_operation
SECTION code_graphics
PUBLIC _plot
_plot:
        xor a
        jp bc__graphics_plot_operation
