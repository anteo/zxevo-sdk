        MODULE zx__rtc_scope_begin
EXTERN _bc__mem_shadow_scope_begin
EXTERN _zx_interrupt_save_disable
SECTION code_clib
PUBLIC _zx__rtc_scope_begin

; Disable INT and open the shadow ports. Return H=prior INT, L=prior BF.
; AF/BC/HL volatile, DE/IX/IY preserved.
_zx__rtc_scope_begin:
        call _zx_interrupt_save_disable
        ld h,l
        jp _bc__mem_shadow_scope_begin
