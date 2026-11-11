        MODULE drawto_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _drawto_callee
EXTERN _drawto

; Small-C callee-clean 2 words. Preserve the target result and IX/IY.
_drawto_callee:
        BC_ABI_SMALLC_CALLEE _drawto,2
