        MODULE fillb_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _fillb_callee
EXTERN _fillb

; Small-C callee-clean 4 words. Preserve the target result and IX/IY. Shadow HL is volatile.
_fillb_callee:
        BC_ABI_SMALLC_CALLEE _fillb,4
