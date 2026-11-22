        MODULE ts_zifi_read_events
SECTION code_clib
PUBLIC _ts_zifi_read_events

; Read/acknowledge or arm the four FIFO events. Read returns L, write takes L.
; Both clobber AF/BC, read also clobbers L. Preserve DE/H/IX/IY.
_ts_zifi_read_events:
        ld bc,0c4efh
        in a,(c)
        and 0fh
        ld l,a
        ret
