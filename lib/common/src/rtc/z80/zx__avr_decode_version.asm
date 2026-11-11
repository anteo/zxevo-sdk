        MODULE zx__avr_decode_version
SECTION code_clib
PUBLIC _zx__avr_decode_version

; Decode the 16-byte AVR application or bootloader record.
;
; copy(version.name, bytes, 16);       // name, packed date and CRC
; version.year = 2000 + ((version.date >> 9) & 63);
; version.official = version.date >> 15;
; version.month = (version.date >> 5) & 15;
; version.day = version.date & 31;
;
; SDCC input pointer at SP+2 and output pointer at SP+4. Both are valid and
; nonoverlapping. The packed prefix matches the first 16 bytes of the C
; structure in little-endian order. DE walks the output after LDIR. The
; stack saves the date while BC is reused. Preserve IX/IY.
_zx__avr_decode_version:
        ld hl,2
        add hl,sp
        ld c,(hl)
        inc hl
        ld b,(hl)
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld h,b
        ld l,c
        ld bc,16
        ldir
        ld bc,-4
        add hl,bc
        ld c,(hl)                    ; packed date low
        inc hl
        ld b,(hl)                    ; packed date high

        ld a,b
        rrca
        and 3fh
        ld l,a
        ld h,0
        push bc
        ld bc,2000
        add hl,bc
        ld a,l
        ld (de),a
        inc de
        ld a,h
        ld (de),a
        inc de
        pop bc

        ld a,b
        rlca
        and 1
        ld (de),a
        inc de
        ld a,c
        rlca
        rlca
        rlca
        and 7
        bit 0,b
        jr z,@month
        or 8
@month:
        ld (de),a
        inc de
        ld a,c
        and 1fh
        ld (de),a
        ret
