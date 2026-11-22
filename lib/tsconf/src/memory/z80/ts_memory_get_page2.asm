        MODULE ts_memory_get_page2
SECTION code_clib
PUBLIC _ts_memory_get_page2

; Read the programmed Page2 value. Returns the byte in L. Clobbers BC, F and L.
_ts_memory_get_page2:
        ld bc,12afh
        in l,(c)
        ret
