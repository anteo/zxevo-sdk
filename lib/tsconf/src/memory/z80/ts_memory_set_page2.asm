        MODULE ts_memory_set_page2
SECTION code_clib
PUBLIC _ts_memory_set_page2

; Select the RAM page for W2. Fastcall L = value. Clobbers BC only.
_ts_memory_set_page2:
        ld bc,12afh
        out (c),l
        ret
