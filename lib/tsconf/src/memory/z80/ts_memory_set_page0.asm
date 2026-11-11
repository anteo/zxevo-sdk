        MODULE ts_memory_set_page0
SECTION code_clib
PUBLIC _ts_memory_set_page0

; Select the page for W0. Fastcall L = value. Clobbers BC only.
_ts_memory_set_page0:
        ld bc,10afh
        out (c),l
        ret
