        MODULE zx_get_cpu_speed
SECTION code_clib
PUBLIC _zx_get_cpu_speed
EXTERN ts__cpu_speed

; Read the last clock selector known to the SDK.
; Fastcall HL=output, L=status. Leave the output untouched on error.
_zx_get_cpu_speed:
        ld a,h
        or l
        jr z,@invalid
        ld a,(ts__cpu_speed)
        cp 0ffh
        jr z,@unknown
        ld (hl),a
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
@unknown:
        ld l,4                       ; ZX_NOT_INITIALIZED
        ret
