        MODULE ts_memory_page3
SECTION code_clib
PUBLIC _ts_memory_set_page3
PUBLIC _ts_memory_get_page3

; Select the RAM page for W3. Fastcall L = value. Clobbers BC only.
_ts_memory_set_page3:
        ld bc,13afh
        out (c),l
        ret

; Read the programmed Page3 value. Returns the byte in L. Clobbers BC, F and L.
_ts_memory_get_page3:
        ld bc,13afh
        in l,(c)
        ret
