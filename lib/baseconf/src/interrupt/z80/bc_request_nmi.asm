        MODULE bc_request_nmi
SECTION code_clib
PUBLIC _bc_request_nmi

; Request NMI with two consecutive writes to bit 3 of the BF port.
;
; bf = in(0x00bf);
; out(0x00bf, bf | 0x08); out(0x00bf, bf & ~0x08);
; return ZX_OK;
;
; SDCC no arguments, status in L. Preserve DE/H/IX/IY, clobber AF/BC/L.
; NMI can transfer control after the first write. Preserve the sampled
; values of the other BF bits in both writes.
_bc_request_nmi:
        ld bc,00BFh
        in a,(c)
        or 08h
        out (c),a
        and 0F7h
        out (c),a
        ld l,0                       ; ZX_OK
        ret
