        MODULE ts_dma_wait
SECTION code_clib
PUBLIC _ts_dma_wait

; Wait for the engine to become idle. DMA must be able to finish.
;
; while (in_ts(0x27) & 0x80) {}
;
; SDCC classic, no arguments or local frame. Clobbers AF and BC.
; Preserves DE, HL, IX, IY and SP.
_ts_dma_wait:
        ld bc,27afh
@poll:
        in a,(c)
        jp m,@poll
        ret
