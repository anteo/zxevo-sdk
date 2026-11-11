        MODULE zx_interrupt_save_disable

SECTION code_clib
PUBLIC _zx_interrupt_save_disable

; Return L=(IFF2!=0), then DI; no arguments. AF/L volatile; H/BC/DE/IX/IY
; preserved. Save the result for interrupt_restore; this function never executes
; EI and does not mask NMI.
_zx_interrupt_save_disable:
        ld a,i
        ld l,0
        jp po,@irq_was_disabled
        inc l
@irq_was_disabled:
        di
        ret
