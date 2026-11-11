        MODULE xordrawb_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _xordrawb_callee
EXTERN _xordrawb

; Small-C callee-clean 4 words. Preserve the target result and IX/IY. Shadow HL is volatile.
_xordrawb_callee:
        BC_ABI_SMALLC_CALLEE _xordrawb,4
