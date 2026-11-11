        MODULE ts_io_read_status
SECTION code_clib
PUBLIC _ts_io_read_status

; Read Status and acknowledge its read-to-clear latches. Returns the byte in L. Clobbers BC, F and L.
_ts_io_read_status:
        ld bc,00afh
        in l,(c)
        ret
