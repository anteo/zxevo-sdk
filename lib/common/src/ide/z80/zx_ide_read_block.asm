        MODULE zx_ide_read_block

SECTION code_clib
PUBLIC _zx_ide_read_block

; SDCC caller-clean ABI: data_port:8 at SP+2, reset_address:16 at SP+3,
; buffer:16 at SP+5. Return ZX_OK=0 or ZX_INVALID_ARGUMENT=1; preserve IX/IY.
;
; Resynchronizes the Nemo IDE byte order and reads one 512-byte block into
; the caller's buffer.
;
; Model:
;
; if (!buffer || data_port!=0x10 || (uint8_t)reset_address==0x10) return INVALID_ARGUMENT;
; IN(reset_address); transfer_512_bytes_with_two_INIR_bursts(buffer,0x10); return OK;
;
; Caller establishes the IDE command/device state and supplies 512 accessible
; buffer bytes. AF/BC/DE/HL volatile; IX/IY preserved, status in HL.
; The reset-port read synchronizes Nemo low/high byte alternation. B=0 means
; 256 transfers, not zero; changing the high port byte is intentional.
_zx_ide_read_block:
        ld hl,2
        add hl,sp
        ld a,(hl)
        cp 10h
        jr nz,@invalid
        inc hl
        ld c,(hl)
        inc hl
        ld b,(hl)
        ld a,c
        cp 10h
        jr z,@invalid
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld a,d
        or e
        jr z,@invalid
        in a,(c)                    ; reset Nemo's low/high byte alternation
        ex de,hl
        ld bc,0010h
        inir
        ld b,0
        inir
        ld hl,0
        ret
@invalid:
        ld hl,1
        ret
