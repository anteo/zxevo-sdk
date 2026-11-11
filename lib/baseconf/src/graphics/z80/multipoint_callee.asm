        MODULE multipoint_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _multipoint_callee
EXTERN _multipoint

; Small-C callee-clean 4 words. Preserve the target result and IX/IY. Shadow HL is volatile.
_multipoint_callee:
        BC_ABI_SMALLC_CALLEE _multipoint,4
