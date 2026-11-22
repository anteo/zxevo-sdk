        MODULE ts_fmaps_disable
SECTION code_clib
PUBLIC _ts_fmaps_disable

; Disable FMAPS. No arguments or result. Clobbers AF and BC only.
_ts_fmaps_disable:
        xor a
        ld bc,15afh
        out (c),a
        ret
