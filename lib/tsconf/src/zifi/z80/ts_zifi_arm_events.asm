        MODULE ts_zifi_arm_events
SECTION code_clib
PUBLIC _ts_zifi_arm_events

_ts_zifi_arm_events:
        ld a,l
        and 0fh
        ld bc,0c4efh
        out (c),a
        ret
