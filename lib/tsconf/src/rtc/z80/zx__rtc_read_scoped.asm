        MODULE zx__rtc_read_scoped
SECTION code_clib
PUBLIC _zx__rtc_read_scoped

; Select the RTC register and read its byte. Fastcall L = index/result.
; AF/BC clobbered. The caller serializes GlukClock use.
_zx__rtc_read_scoped:
        ld bc,0DFF7h
        out (c),l
        ld b,0BFh
        in l,(c)
        ret
