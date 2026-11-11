        MODULE undrawto_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _undrawto_callee
EXTERN _undrawto

; Small-C callee-clean 2 words. Preserve the target result and IX/IY.
_undrawto_callee:
        BC_ABI_SMALLC_CALLEE _undrawto,2
