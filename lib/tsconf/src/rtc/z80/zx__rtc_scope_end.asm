        MODULE zx__rtc_scope_end
EXTERN _zx_interrupt_restore
SECTION code_clib
PUBLIC _zx__rtc_scope_end

; Restore INT from the low byte of the fastcall scope word.
defc _zx__rtc_scope_end = _zx_interrupt_restore
