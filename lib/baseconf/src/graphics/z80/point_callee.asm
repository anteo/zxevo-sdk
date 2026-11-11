        MODULE point_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _point_callee
EXTERN _point

; Small-C callee-clean 2 words. Preserve the target result and IX/IY.
_point_callee:
        BC_ABI_SMALLC_CALLEE _point,2
