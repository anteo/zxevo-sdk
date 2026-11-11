        MODULE ts_memory_page2
SECTION code_clib
PUBLIC _ts_memory_set_page2
PUBLIC _ts_memory_get_page2

; Select the RAM page for W2. Fastcall L = value. Clobbers BC only.
_ts_memory_set_page2:
        ld bc,12afh
        out (c),l
        ret

; Read the programmed Page2 value. Returns the byte in L. Clobbers BC, F and L.
_ts_memory_get_page2:
        ld bc,12afh
        in l,(c)
        ret
