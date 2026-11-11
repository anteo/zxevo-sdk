        MODULE ts_fdr_read_count
SECTION code_clib
PUBLIC _ts_fdr_read_count

; Latch and read the FDR 19-bit count.
;
; if (!count) return ZX_INVALID_ARGUMENT;
; low = IN(0x30af);
; middle = IN(0x31af);
; high = IN(0x32af) & 7;
; *count = low | ((uint32_t)middle << 8) | ((uint32_t)high << 16);
; return ZX_OK;
;
; Fastcall HL = output, L = status. Caller has an FDR build and excludes
; competing count reads. Clobber AF/BC/HL, preserve DE/IX/IY.
_ts_fdr_read_count:
        ld a,h
        or l
        jr z,@invalid
        ld bc,30afh
        in a,(c)
        ld (hl),a
        inc hl
        inc b
        in a,(c)
        ld (hl),a
        inc hl
        inc b
        in a,(c)
        and 7
        ld (hl),a
        inc hl
        ld (hl),0
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
