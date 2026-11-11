        MODULE zx__rtc_scope
SECTION code_clib
PUBLIC _zx__rtc_scope_begin
PUBLIC _zx__rtc_scope_end
EXTERN _zx_interrupt_save_disable
EXTERN _zx_interrupt_restore
EXTERN _bc__mem_shadow_scope_begin
EXTERN _bc__mem_shadow_scope_end

; Disable INT and open the shadow ports. Return H=prior INT, L=prior BF.
; AF/BC/HL volatile, DE/IX/IY preserved.
_zx__rtc_scope_begin:
        call _zx_interrupt_save_disable
        ld h,l
        jp _bc__mem_shadow_scope_begin

; Restore the saved scope. Fastcall H=prior INT, L=prior BF.
_zx__rtc_scope_end:
        call _bc__mem_shadow_scope_end
        ld l,h
        jp _zx_interrupt_restore
