        MODULE draw_callee
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _draw_callee
EXTERN _draw

; Small-C callee-clean 4 words. Preserve the target result and IX/IY. Shadow HL is volatile.
_draw_callee:
        BC_ABI_SMALLC_CALLEE _draw,4
