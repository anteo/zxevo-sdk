        MODULE ts_memory_set_page3
SECTION code_clib
PUBLIC _ts_memory_set_page3

; Select the RAM page for W3. Fastcall L = value. Clobbers BC only.
_ts_memory_set_page3:
        ld bc,13afh
        out (c),l
        ret
