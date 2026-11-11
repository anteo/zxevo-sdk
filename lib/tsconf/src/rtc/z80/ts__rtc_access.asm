        MODULE ts__rtc_access
SECTION code_clib
PUBLIC _zx__rtc_read_scoped
PUBLIC _zx__rtc_write_scoped

; Select the RTC register and read its byte. Fastcall L = index/result.
; AF/BC clobbered. The caller serializes GlukClock use.
_zx__rtc_read_scoped:
        ld bc,0DFF7h
        out (c),l
        ld b,0BFh
        in l,(c)
        ret

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
