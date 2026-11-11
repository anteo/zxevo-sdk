        MODULE circle_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _circle_callee
EXTERN _circle

; Small-C callee-clean 4 words. Preserve the target result and IX/IY. Shadow HL is volatile.
_circle_callee:
        BC_ABI_SMALLC_CALLEE _circle,4
