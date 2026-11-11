        MODULE xorclga_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _xorclga_callee
EXTERN _xorclga

; Small-C callee-clean 4 words. Preserve the target result and IX/IY. Shadow HL is volatile.
_xorclga_callee:
        BC_ABI_SMALLC_CALLEE _xorclga,4
