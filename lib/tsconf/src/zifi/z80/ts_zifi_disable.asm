        MODULE ts_zifi_disable
SECTION code_clib
PUBLIC _ts_zifi_disable

; Disable the legacy ZiFi FIFO API. Clobber AF/BC.
_ts_zifi_disable:
        ld bc,0c7efh
        ld a,0f0h
        out (c),a
        ret
