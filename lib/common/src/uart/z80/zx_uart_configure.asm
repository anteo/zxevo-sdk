        MODULE zx_uart_configure
SECTION code_clib
PUBLIC _zx_uart_configure

; Validate the framing, program the divisor and reset the FIFOs.
;
; if (!configuration || bits < 5 || bits > 8 || parity > 2 ||
;     (stop_bits != 1 && stop_bits != 2)) return ZX_INVALID_ARGUMENT;
; lcr = (bits - 5) | (stop_bits == 2 ? 4 : 0) |
;       (parity == ODD ? 8 : parity == EVEN ? 0x18 : 0);
; out(LCR, 0x80);
; out(DLL, low(divisor)); out(DLH, high(divisor));
; out(LCR, lcr); out(FCR, 7); out(MCR, in(MCR) | 2);
; return ZX_OK;
;
; SDCC configuration pointer at SP+2, status in L. Fields are bits, parity,
; stop_bits and the two divisor bytes in that order. D/H hold divisor low/high
; and E holds LCR. Preserve IX/IY, clobber AF/BC/DE/HL.
_zx_uart_configure:
        ld hl,2
        add hl,sp
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        or h
        jr z,@invalid
        ld a,(hl)
        sub 5
        cp 4
        jr nc,@invalid
        ld e,a
        inc hl
        ld a,(hl)
        cp 3
        jr nc,@invalid
        or a
        jr z,@stop_bits
        set 3,e
        dec a
        jr z,@stop_bits
        set 4,e
@stop_bits:
        inc hl
        ld a,(hl)
        dec a
        jr z,@program
        dec a
        jr nz,@invalid
        set 2,e
@program:
        inc hl
        ld d,(hl)
        inc hl
        ld h,(hl)
        ld bc,0FBEFh
        ld a,80h
        out (c),a
        ld b,0F8h
        out (c),d
        inc b
        out (c),h
        ld b,0FBh
        out (c),e
        dec b
        ld a,7
        out (c),a
        ld b,0FCh
        in a,(c)
        or 2
        out (c),a
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
