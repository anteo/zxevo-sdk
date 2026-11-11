        MODULE xordraw_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _xordraw_callee
EXTERN _xordraw

; Small-C callee-clean 4 words. Preserve the target result and IX/IY. Shadow HL is volatile.
_xordraw_callee:
        BC_ABI_SMALLC_CALLEE _xordraw,4
