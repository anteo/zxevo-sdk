        MODULE undraw_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _undraw_callee
EXTERN _undraw

; Small-C callee-clean 4 words. Preserve the target result and IX/IY. Shadow HL is volatile.
_undraw_callee:
        BC_ABI_SMALLC_CALLEE _undraw,4
