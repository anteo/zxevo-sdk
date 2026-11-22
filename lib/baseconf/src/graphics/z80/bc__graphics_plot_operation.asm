        MODULE bc__graphics_plot_operation
INCLUDE "abi.inc"
EXTERN _bc__graphics_begin
EXTERN bc__graphics_plot_point
SECTION code_graphics
PUBLIC bc__graphics_plot_operation

bc__graphics_plot_operation:
        push af
        call _bc__graphics_begin
        pop bc
        ret z
        ld a,b
        BC_ABI_LOAD_SMALLC_PAIR
        jp bc__graphics_plot_point
