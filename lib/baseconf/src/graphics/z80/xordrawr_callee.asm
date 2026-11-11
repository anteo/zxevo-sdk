        MODULE xordrawr_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _xordrawr_callee
EXTERN _xordrawr

; Small-C callee-clean 2 words. Preserve the target result and IX/IY.
_xordrawr_callee:
        BC_ABI_SMALLC_CALLEE _xordrawr,2
