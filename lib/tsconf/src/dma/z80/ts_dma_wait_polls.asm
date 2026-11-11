        MODULE ts_dma_wait_polls
SECTION code_clib
PUBLIC _ts_dma_wait_polls

; Wait for DMA idle with a bounded number of status reads.
;
; while (polls--) if (!(IN(0x27af) & 0x80)) return ZX_OK;
; return ZX_TIMEOUT;
;
; Fastcall HL = poll budget, L = status. Clobber AF/BC/HL, preserve DE/IX/IY.
_ts_dma_wait_polls:
        ld bc,27afh
@poll:
        ld a,h
        or l
        jr z,@timeout
        in a,(c)
        rlca
        jr nc,@idle
        dec hl
        jr @poll
@idle:
        ld l,0                       ; ZX_OK
        ret
@timeout:
        ld l,7                       ; ZX_TIMEOUT
        ret
