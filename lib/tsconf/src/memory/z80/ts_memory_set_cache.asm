        MODULE ts_memory_set_cache
SECTION code_clib
PUBLIC _ts_memory_set_cache
EXTERN ts__cache_mask

; Write and record the per-window cache mask. Fastcall L=value, preserved.
; Clobber AF/BC. Serialize register access.
_ts_memory_set_cache:
        ld bc,2bafh
        out (c),l
        ld a,l
        and 0fh
        ld (ts__cache_mask),a
        ret
