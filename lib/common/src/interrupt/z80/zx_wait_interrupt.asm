        MODULE zx_wait_interrupt

SECTION code_clib
PUBLIC _zx_wait_interrupt

; Wait for an interrupt when maskable interrupts are enabled and return
; ZX_UNSAFE_CONTEXT otherwise.
;
; Model:
;
; if (!IFF2) return UNSAFE_CONTEXT; HALT(); return OK;
;
; No arguments; HL=status, AF volatile, BC/DE/IX/IY preserved by this routine
; (interrupt handlers must preserve the caller's context). LD A,I reports
; IFF2 in P/V. An INT handled before HALT does not count as its wakeup.
; Any enabled INT source or NMI can wake HALT.
_zx_wait_interrupt:
        ld a,i
        jp po,@interrupts_disabled
        halt
        ld hl,0
        ret
@interrupts_disabled:
        ld hl,6
        ret
