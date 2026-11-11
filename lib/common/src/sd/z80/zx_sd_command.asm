        MODULE zx_sd_command
SECTION code_clib
PUBLIC _zx_sd_command
EXTERN _zx__sd_active_transaction

defc SD_COMMAND_HANDLE = 4
defc SD_COMMAND_NUMBER = 6
defc SD_COMMAND_ARG_MSB = 10
defc SD_COMMAND_R1 = 11

; Send an SPI command and read its R1 byte, leaving the next byte pending.
;
; if (!current(transaction) || command >= 64 || !r1) return ZX_INVALID_ARGUMENT;
; crc = 0;
; for (byte : {0x40 | command, argument in big-endian order}) {
;     crc = crc7_update(crc, byte);
;     OUT(0x0057, byte);
; }
; OUT(0x0057, (crc << 1) | 1);
; transaction->transfer_pending = 1;
; if (command == 12) { IN(0x0057); IN(0x0057); }
; for (i = 0; i < 16; ++i)
;     if ((response = IN(0x0057)) < 0x80) { *r1 = response; return ZX_OK; }
; return ZX_TIMEOUT;
;
; SDCC with saved IX: handle at IX+4, command at IX+6, argument at
; IX+7..10 and result pointer at IX+11. Status in L, preserve IX/IY.
; AF/BC/DE/HL volatile. IN retrieves the previous byte and clocks the next.
_zx_sd_command:
        push ix
        ld ix,0
        add ix,sp
        ld e,(ix+SD_COMMAND_HANDLE)
        ld d,(ix+SD_COMMAND_HANDLE+1)
        ld a,d
        or e
        jr z,@invalid
        ld hl,(_zx__sd_active_transaction)
        or a
        sbc hl,de
        jr nz,@invalid
        ld a,(ix+SD_COMMAND_R1)
        or (ix+SD_COMMAND_R1+1)
        jr z,@invalid
        ld a,(ix+SD_COMMAND_NUMBER)
        cp 64
        jr nc,@invalid

        or 40h
        ld bc,0057h
        ld e,0
        call @send
        push ix
        pop hl
        ld de,SD_COMMAND_ARG_MSB
        add hl,de
        ; Restore the CRC from A and walk the little-endian argument backward.
        ld e,a
        ld d,4
@argument:
        ld a,(hl)
        call @send
        dec hl
        dec d
        jr nz,@argument
        or 1
        out (c),a
        ld hl,(_zx__sd_active_transaction)
        inc hl
        inc hl
        ld (hl),1
        ld a,(ix+SD_COMMAND_NUMBER)
        cp 12
        jr nz,@start_poll
        in a,(c)                     ; discard MISO from the command's CRC byte
        in a,(c)                     ; CMD12 inserts one stuff byte before R1
@start_poll:
        ld hl,16
@poll:
        in a,(c)
        jp p,@response
        dec l
        jr nz,@poll
        ld l,7                       ; ZX_TIMEOUT
        jr @done
@response:
        ld l,(ix+SD_COMMAND_R1)
        ld h,(ix+SD_COMMAND_R1+1)
        ld (hl),a
        ld l,0
        jr @done
@invalid:
        ld l,1
@done:
        pop ix
        ret

; Fold and transmit A, preserving HL/D. E and A return left-aligned CRC7.
; The polynomial x^7+x^3+1 becomes 12h in this representation.
@send:
        out (c),a
        xor e
        ld b,8
@crc_bit:
        add a,a
        jr nc,@crc_next
        xor 12h
@crc_next:
        djnz @crc_bit               ; B returns to zero for the next SPI output
        ld e,a
        ret
