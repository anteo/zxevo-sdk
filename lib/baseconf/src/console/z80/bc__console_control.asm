        MODULE bc__console_control
EXTERN bc__console_control_a
SECTION code_clib
PUBLIC _bc__console_control

; Pass the SDCC fastcall character in L to the native control handler in A.
_bc__console_control:
        ld a,l
        jp bc__console_control_a
