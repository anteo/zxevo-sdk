        MODULE cplot_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _cplot_callee
EXTERN _cplot

; Small-C callee-clean 3 words. Preserve the target result and IX/IY.
_cplot_callee:
        BC_ABI_SMALLC_CALLEE _cplot,3
