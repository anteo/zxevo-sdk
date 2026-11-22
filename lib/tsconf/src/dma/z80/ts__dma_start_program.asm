        MODULE ts__dma_start_program
SECTION code_clib
PUBLIC ts__dma_start_program

; Set both physical addresses and the burst shape, then launch DMA.
;
; for (reg = 0x1a; reg <= 0x1f; ++reg)
;     out_ts(reg, *address_bytes++);
; out_ts(0x26, transfer->words_minus_one);
; out_ts(0x28, transfer->bursts_minus_one);
; out_ts(0x2c, burst_high & 3);
; out_ts(0x27, transfer->control);
;
; Fastcall HL = transfer and zero upper burst count. Extended caller-clean
; entry has transfer at SP+2 and burst_high at SP+4. SDCC lays out each
; address as low offset byte, high offset byte and physical page.
; A holds the upper burst bits across OUTI. Clobber AF/BC/HL and, for the
; extended entry only, DE. Preserve IX/IY and SP.
; Caller owns the idle engine and uses uncached CPU aliases of its buffers.
ts__dma_start_program:
        ; OUTI uses B after decrementing it, so start at 1Bh for port 1AAFh
        ; and add two between writes to reach the next register.
        ld bc,1bafh
        REPT 5
        outi
        inc b
        inc b
        ENDR
        outi
        ld b,27h
        outi
        ld b,29h
        outi
        ; Only FDR builds decode the upper burst count.
        ld b,2ch
        out (c),a
        ld b,28h
        outi
        ret
