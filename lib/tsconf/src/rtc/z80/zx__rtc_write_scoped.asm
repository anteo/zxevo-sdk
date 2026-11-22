        MODULE zx__rtc_write_scoped
SECTION code_clib
PUBLIC _zx__rtc_write_scoped

; Write the RTC byte. SDCC stack index at SP+2 and value at SP+3.
; AF/BC/HL clobbered. The caller serializes GlukClock use.
_zx__rtc_write_scoped:
        ld hl,2
        add hl,sp
        ld bc,0DFF7h
        ld a,(hl)
        out (c),a
        inc hl
        ld b,0BFh
        ld l,(hl)
        out (c),l
        ret
