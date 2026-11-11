        MODULE zx_rtc_write
SECTION code_clib
PUBLIC _zx_rtc_write
EXTERN _bc__rtc_write_byte

; Validate the RTC index, then use the ordinary RTC write scope.
; SDCC index at SP+2, value at SP+3, status in L.
; Preserve IX/IY, clobber AF/BC/DE/HL.
_zx_rtc_write:
        ld hl,2
        add hl,sp
        ld a,(hl)
        cp 16
        jr nc,@invalid
        jp _bc__rtc_write_byte
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
