        MODULE ts_dma_start
EXTERN ts__dma_start_program
SECTION code_clib
PUBLIC _ts_dma_start

; Start a DMA transfer from the descriptor in HL using zero upper burst bits.
_ts_dma_start:
        xor a
        jp ts__dma_start_program
