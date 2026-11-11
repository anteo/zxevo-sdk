        MODULE ts_rtc_set_enabled
SECTION code_clib
PUBLIC _ts_rtc_set_enabled

; Select GlukClock outside DOS. Fastcall L = boolean. AF/BC clobbered.
_ts_rtc_set_enabled:
        ld a,l
        or a
        jr z,@write
        ld a,80h
@write:
        ld bc,0EFF7h
        out (c),a
        ret
