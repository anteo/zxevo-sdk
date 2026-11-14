SECTION code_clib
PUBLIC _im2_Init_fastcall
EXTERN _im2_Init
; Fastcall HL=aligned vector table; z88dk owns IM2 setup. No extra ISR engine.
defc _im2_Init_fastcall = _im2_Init
