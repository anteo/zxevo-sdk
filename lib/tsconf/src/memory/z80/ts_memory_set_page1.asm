        MODULE ts_memory_set_page1
SECTION code_clib
PUBLIC _ts_memory_set_page1

; Select the RAM page for W1. Fastcall L = value. Clobbers BC only.
_ts_memory_set_page1:
        ld bc,11afh
        out (c),l
        ret
