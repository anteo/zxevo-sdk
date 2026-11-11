        MODULE undrawr_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _undrawr_callee
EXTERN _undrawr

; Small-C callee-clean 2 words. Preserve the target result and IX/IY.
_undrawr_callee:
        BC_ABI_SMALLC_CALLEE _undrawr,2
