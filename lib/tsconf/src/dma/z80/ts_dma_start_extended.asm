        MODULE ts_dma_start_extended
EXTERN ts__dma_start_program
SECTION code_clib
PUBLIC _ts_dma_start_extended
_ts_dma_start_extended:
        ld hl,2
        add hl,sp
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld a,(hl)
        and 3
        ex de,hl
        jp ts__dma_start_program
