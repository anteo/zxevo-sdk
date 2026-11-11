        MODULE ts_fdd_set_config
SECTION code_clib
PUBLIC _ts_fdd_set_config

; Set FDDVirt from L, clearing reserved bits. AF/BC clobbered.
_ts_fdd_set_config:
        ld a,l
        and 8Fh
        ld bc,29AFh
        out (c),a
        ret
