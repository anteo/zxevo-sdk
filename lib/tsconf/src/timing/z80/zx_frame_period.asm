        MODULE zx_frame_period
SECTION code_clib
PUBLIC _zx_frame_period

defc TS_FRAME_TSTATES = 224 * TSCONF_FRAME_LINES
defc TS_FRAME_PERIOD_LOW = TS_FRAME_TSTATES & 0ffh
defc TS_FRAME_PERIOD_MIDDLE = (TS_FRAME_TSTATES >> 8) & 0ffh
defc TS_FRAME_PERIOD_HIGH = TS_FRAME_TSTATES >> 16

; Store the build's nominal frame length at 3.5 MHz.
; Fastcall HL = little-endian uint32_t output or NULL, L = status.
; Clobber AF/HL, preserve BC/DE/IX/IY.
_zx_frame_period:
        ld a,h
        or l
        jr z,@invalid
        ld (hl),TS_FRAME_PERIOD_LOW
        inc hl
        ld (hl),TS_FRAME_PERIOD_MIDDLE
        inc hl
        ld (hl),TS_FRAME_PERIOD_HIGH
        inc hl
        ld (hl),0
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
