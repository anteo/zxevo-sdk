        MODULE plot_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _plot_callee
EXTERN _plot

; Small-C callee-clean 2 words. Preserve the target result and IX/IY.
_plot_callee:
        BC_ABI_SMALLC_CALLEE _plot,2
