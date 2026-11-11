        MODULE ts_zifi_enable
SECTION code_clib
PUBLIC _ts_zifi_enable

; Enable legacy ZiFi API 1 and return the AVR's reported version in L.
; Clobber AF/BC/L, preserve DE/H/IX/IY.
_ts_zifi_enable:
        ld bc,0c7efh
        ld a,0f1h
        out (c),a
        ld a,0ffh
        out (c),a
        in l,(c)
        ret
