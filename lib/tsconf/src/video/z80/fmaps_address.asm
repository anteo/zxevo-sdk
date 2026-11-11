        MODULE ts_fmaps_address
SECTION code_clib
PUBLIC _ts_fmaps_enable
PUBLIC _ts_fmaps_disable

; Map FMAPS over a disposable, 4 KiB-aligned CPU address.
;
; out_ts(0x15, 0x10 | (base >> 12));
;
; Fastcall HL = base. No stack frame. Clobbers AF and BC only.
_ts_fmaps_enable:
        ld a,h
        ; Address bits 15:12 become FMAddr bits 3:0.
        rlca
        rlca
        rlca
        rlca
        and 0fh
        or 10h
        ld bc,15afh
        out (c),a
        ret

; Disable FMAPS. No arguments or result. Clobbers AF and BC only.
_ts_fmaps_disable:
        xor a
        ld bc,15afh
        out (c),a
        ret
