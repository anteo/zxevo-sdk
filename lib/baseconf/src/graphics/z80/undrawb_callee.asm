        MODULE undrawb_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _undrawb_callee
EXTERN _undrawb

; Small-C callee-clean 4 words. Preserve the target result and IX/IY. Shadow HL is volatile.
_undrawb_callee:
        BC_ABI_SMALLC_CALLEE _undrawb,4
