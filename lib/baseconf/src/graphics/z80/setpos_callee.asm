        MODULE setpos_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _setpos_callee
EXTERN _setpos

; Small-C callee-clean 2 words. Preserve the target result and IX/IY.
_setpos_callee:
        BC_ABI_SMALLC_CALLEE _setpos,2
