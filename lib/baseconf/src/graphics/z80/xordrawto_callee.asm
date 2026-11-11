        MODULE xordrawto_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _xordrawto_callee
EXTERN _xordrawto

; Small-C callee-clean 2 words. Preserve the target result and IX/IY.
_xordrawto_callee:
        BC_ABI_SMALLC_CALLEE _xordrawto,2
