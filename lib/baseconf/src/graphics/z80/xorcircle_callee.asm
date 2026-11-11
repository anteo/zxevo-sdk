        MODULE xorcircle_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _xorcircle_callee
EXTERN _xorcircle

; Small-C callee-clean 4 words. Preserve the target result and IX/IY. Shadow HL is volatile.
_xorcircle_callee:
        BC_ABI_SMALLC_CALLEE _xorcircle,4
