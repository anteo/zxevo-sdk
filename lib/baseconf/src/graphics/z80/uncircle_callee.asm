        MODULE uncircle_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _uncircle_callee
EXTERN _uncircle

; Small-C callee-clean 4 words. Preserve the target result and IX/IY. Shadow HL is volatile.
_uncircle_callee:
        BC_ABI_SMALLC_CALLEE _uncircle,4
