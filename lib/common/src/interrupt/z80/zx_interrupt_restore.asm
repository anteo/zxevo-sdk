        MODULE zx_interrupt_restore

SECTION code_clib
PUBLIC _zx_interrupt_restore

; Fastcall L=previous interrupt-enabled boolean. If nonzero, EI immediately
; before RET; otherwise leave INT disabled. AF volatile, BC/DE/HL/IX/IY
; preserved. Caller must already have disabled INT when restoring zero.
_zx_interrupt_restore:
        ld a,l
        or a
        ret z
        ei
        ret
