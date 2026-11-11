        MODULE cpoint_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _cpoint_callee
EXTERN _cpoint

; Small-C callee-clean 2 words. Preserve the target result and IX/IY.
_cpoint_callee:
        BC_ABI_SMALLC_CALLEE _cpoint,2
