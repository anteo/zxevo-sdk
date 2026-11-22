        MODULE zx__rtc_scope_end
EXTERN _bc__mem_shadow_scope_end
EXTERN _zx_interrupt_restore
SECTION code_clib
PUBLIC _zx__rtc_scope_end

; Restore the saved scope. Fastcall H=prior INT, L=prior BF.
_zx__rtc_scope_end:
        call _bc__mem_shadow_scope_end
        ld l,h
        jp _zx_interrupt_restore
