        MODULE zx__rtc_scope
SECTION code_clib
PUBLIC _zx__rtc_scope_begin
PUBLIC _zx__rtc_scope_end
EXTERN _zx_interrupt_save_disable
EXTERN _zx_interrupt_restore

; Mask INT. GlukClock ports are already enabled by the caller.
; Return the prior INT state as a word in HL.
_zx__rtc_scope_begin:
        call _zx_interrupt_save_disable
        ld h,0
        ret

; Restore INT from the low byte of the fastcall scope word.
defc _zx__rtc_scope_end = _zx_interrupt_restore
