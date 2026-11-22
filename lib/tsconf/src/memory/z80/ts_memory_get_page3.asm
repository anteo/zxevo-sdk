        MODULE ts_memory_get_page3
SECTION code_clib
PUBLIC _ts_memory_get_page3

; Read the programmed Page3 value. Returns the byte in L. Clobbers BC, F and L.
_ts_memory_get_page3:
        ld bc,13afh
        in l,(c)
        ret
