        MODULE zx__printf_unsigned_string
SECTION code_clib
PUBLIC _zx__printf_unsigned_string

defc ZX_PRINTF_VALUE = 4
defc ZX_PRINTF_RADIX = 6
defc ZX_PRINTF_UPPER = 7
defc ZX_PRINTF_END = 8

; Format an unsigned 16-bit value into the end of a five-byte buffer.
;
; p = end;
; do {
;     if (radix == 16) { digit = value & 15; value >>= 4; }
;     else { (value, digit) = divmod10(value); }
;     *--p = digit < 10 ? '0' + digit : (upper ? 'A' : 'a') + digit - 10;
; } while (value);
; return end - p;
;
; SDCC caller-clean value word, radix and upper bytes, then end pointer.
; IX points at saved IX. Radix is 10 or 16, upper is 0 or 1 and the caller
; provides five writable bytes before end. HL holds the remaining value,
; DE walks backwards from end and the original end is saved on the stack.
; Return length in L. Preserve IX/IY, clobber AF/BC/DE/HL.
_zx__printf_unsigned_string:
        push ix
        ld ix,0
        add ix,sp
        ld l,(ix+ZX_PRINTF_VALUE)
        ld h,(ix+ZX_PRINTF_VALUE+1)
        ld e,(ix+ZX_PRINTF_END)
        ld d,(ix+ZX_PRINTF_END+1)
        push de
@next_digit:
        ld a,(ix+ZX_PRINTF_RADIX)
        cp 16
        jr nz,@decimal
        ld a,l
        and 0Fh
        ld b,4
@hex_shift:
        srl h
        rr l
        djnz @hex_shift
        cp 10
        jr c,@numeric
        bit 0,(ix+ZX_PRINTF_UPPER)
        jr nz,@upper
        add a,'a'-10
        jr @write
@upper:
        add a,'A'-10
        jr @write
@decimal:
        call @divmod10
@numeric:
        add a,'0'
@write:
        dec de
        ld (de),a
        ld a,h
        or l
        jr nz,@next_digit
        pop hl
        or a
        sbc hl,de
        pop ix
        ret

; Divide unsigned HL by ten. Return quotient in HL and remainder in A.
; Each shift consumes one input bit and opens a low bit for the quotient.
@divmod10:
        ld b,16
        xor a
@divide_bit:
        add hl,hl
        rla
        cp 10
        jr c,@quotient_bit
        sub 10
        inc l
@quotient_bit:
        djnz @divide_bit
        ret
