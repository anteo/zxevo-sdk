        MODULE xorplot_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _xorplot_callee
EXTERN _xorplot

; Small-C callee-clean 2 words. Preserve the target result and IX/IY.
_xorplot_callee:
        BC_ABI_SMALLC_CALLEE _xorplot,2
