        MODULE ts_dma_configure_wait_port
SECTION code_clib
PUBLIC _ts_dma_configure_wait_port

; Configure the AVR service and its address for WAIT-port DMA.
;
; if (device > 1) return ZX_INVALID_ARGUMENT;
; OUT(0x25af, device);
; OUT(0x2daf, address);
; return ZX_OK;
;
; Caller-clean device at SP+2, address at SP+3, status in L. Caller owns
; the idle DMA engine and serializes access to the shared WAIT address latch.
; Clobber AF/BC/HL, preserve DE/IX/IY.
_ts_dma_configure_wait_port:
        ld hl,2
        add hl,sp
        ld a,(hl)
        cp 2
        jr nc,@invalid
        ld bc,25afh
        out (c),a
        inc hl
        ld b,2eh                     ; OUTI decrements B before the port write
        outi
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
