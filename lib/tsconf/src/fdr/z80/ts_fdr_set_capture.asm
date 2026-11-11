        MODULE ts_fdr_set_capture
SECTION code_clib
PUBLIC _ts_fdr_set_capture

; Write FDR capture enable. Fastcall L = 0 or 1, clobber A/BC.
_ts_fdr_set_capture:
        ld a,l
        and 1
        ld bc,30afh
        out (c),a
        ret
