        MODULE drawr_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _drawr_callee
EXTERN _drawr

; Small-C callee-clean 2 words. Preserve the target result and IX/IY.
_drawr_callee:
        BC_ABI_SMALLC_CALLEE _drawr,2
