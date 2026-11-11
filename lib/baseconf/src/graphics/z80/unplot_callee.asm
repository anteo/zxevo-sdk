        MODULE unplot_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _unplot_callee
EXTERN _unplot

; Small-C callee-clean 2 words. Preserve the target result and IX/IY.
_unplot_callee:
        BC_ABI_SMALLC_CALLEE _unplot,2
