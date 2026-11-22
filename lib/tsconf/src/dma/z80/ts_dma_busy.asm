        MODULE ts_dma_busy
SECTION code_clib
PUBLIC _ts_dma_busy

; Return DMAStatus.D7 as an SDCC byte in L.
; Clobbers AF, BC and L. Preserves DE, H, IX, IY and SP.
_ts_dma_busy:
        ld bc,27afh
        in a,(c)
        rlca
        ld l,0
        rl l
        ret
