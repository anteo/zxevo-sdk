        MODULE ts_copper_stop
SECTION code_clib
PUBLIC _ts_copper_stop

_ts_copper_stop:
        ld bc,14afh
        ld a,0ffh
        out (c),a
        ret
