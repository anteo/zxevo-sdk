        MODULE zx_rtc_read
SECTION code_clib
PUBLIC _zx_rtc_read
EXTERN _bc__rtc_read_byte

; Validate the RTC index, then use the ordinary RTC read scope.
; SDCC index at SP+2, output pointer at SP+3, status in L.
; Preserve IX/IY, clobber AF/BC/DE/HL.
_zx_rtc_read:
        ld hl,2
        add hl,sp
        ld a,(hl)
        cp 16
        jr nc,@invalid
        jp _bc__rtc_read_byte
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
