        MODULE drawb_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _drawb_callee
EXTERN _drawb

; Small-C callee-clean 4 words. Preserve the target result and IX/IY. Shadow HL is volatile.
_drawb_callee:
        BC_ABI_SMALLC_CALLEE _drawb,4
