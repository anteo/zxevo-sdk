        MODULE ts_memory_set_config
SECTION code_clib
PUBLIC _ts_memory_set_config

; Write MemConfig. Fastcall L = value. Clobbers BC only.
_ts_memory_set_config:
        ld bc,21afh
        out (c),l
        ret
