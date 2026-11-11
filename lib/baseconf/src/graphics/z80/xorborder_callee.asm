        MODULE xorborder_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _xorborder_callee
EXTERN _xorborder

; Small-C callee-clean 4 words. Preserve the target result and IX/IY. Shadow HL is volatile.
_xorborder_callee:
        BC_ABI_SMALLC_CALLEE _xorborder,4
