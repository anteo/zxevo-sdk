        MODULE zx_interrupt_enable
SECTION code_clib
PUBLIC _zx_interrupt_enable

; Enable INT for any nonzero byte, or disable it for zero. NMI is unaffected.
; SDCC enabled at SP+2. Clobber AF/HL, preserve BC/DE/IX/IY.
_zx_interrupt_enable:
        ld hl,2
        add hl,sp
        ld a,(hl)
        or a
        jr z,@disable
        ei
        ret
@disable:
        di
        ret
