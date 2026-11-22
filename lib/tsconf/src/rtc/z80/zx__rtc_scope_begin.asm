        MODULE zx__rtc_scope_begin
EXTERN _zx_interrupt_save_disable
SECTION code_clib
PUBLIC _zx__rtc_scope_begin

; Mask INT. GlukClock ports are already enabled by the caller.
; Return the prior INT state as a word in HL.
_zx__rtc_scope_begin:
        call _zx_interrupt_save_disable
        ld h,0
        ret
