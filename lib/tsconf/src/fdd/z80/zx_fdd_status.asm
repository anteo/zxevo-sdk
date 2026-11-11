        MODULE zx_fdd_status
SECTION code_clib
PUBLIC _zx_fdd_status

; Read the Beta Disk system byte from FFh. Fastcall HL=output, L=status.
; Beta Disk ports must be open. Clobber AF/BC/HL, preserve DE/IX/IY.
_zx_fdd_status:
        ld a,h
        or l
        jr z,@invalid
        ld bc,00FFh
        in a,(c)
        ld (hl),a
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
