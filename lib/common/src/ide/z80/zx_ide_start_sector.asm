        MODULE zx_ide_start_sector
SECTION code_clib
PUBLIC _zx_ide_start_sector
EXTERN zx__ide_wait_bus
EXTERN zx__ide_wait_idle
EXTERN _zx_ide_wait_data

defc IDE_START_OP = 4
defc IDE_START_LBA = 5
defc IDE_START_POLLS = 9

; Start a single LBA28 transfer on device 0 and wait for the data phase.
;
; if (op > WRITE || lba > 0x0fffffff) return ZX_INVALID_ARGUMENT;
; if ((status = wait_bus(polls)) != ZX_OK) return status;
; select_device(0xe0 | (lba >> 24));
; if ((status = wait_idle(polls)) != ZX_OK) return status;
; set_sector_count(1); set_lba_low_24(lba); issue(op == READ ? 0x20 : 0x30);
; return wait_data(polls);
;
; SDCC caller-clean. With saved IX, arguments are op at IX+4, lba at IX+5,
; poll limit at IX+9. Return in L, preserve IX/IY, clobber AF/BC/DE/HL.
; Calls and argument reloads supply the 400 ns ATA settle interval at 14 MHz.
_zx_ide_start_sector:
        push ix
        ld ix,0
        add ix,sp
        ld a,(ix+IDE_START_OP)
        cp 2
        jr nc,@invalid
        ld a,(ix+IDE_START_LBA+3)
        and 0F0h
        jr nz,@invalid
        ld l,(ix+IDE_START_POLLS)
        ld h,(ix+IDE_START_POLLS+1)
        call zx__ide_wait_bus
        ld a,l
        or a
        jr nz,@done
        ld bc,80D0h
        ld a,(ix+IDE_START_LBA+3)
        or 0E0h
        out (c),a
        ld l,(ix+IDE_START_POLLS)
        ld h,(ix+IDE_START_POLLS+1)
        call zx__ide_wait_idle
        ld a,l
        or a
        jr nz,@done

        ld c,50h
        ld a,1
        out (c),a
        ld c,70h
        ld a,(ix+IDE_START_LBA)
        out (c),a
        ld c,90h
        ld a,(ix+IDE_START_LBA+1)
        out (c),a
        ld c,0B0h
        ld a,(ix+IDE_START_LBA+2)
        out (c),a
        ld c,0F0h
        ld a,(ix+IDE_START_OP)
        or a
        ld a,20h
        jr z,@command
        ld a,30h
@command:
        out (c),a
        ld l,(ix+IDE_START_POLLS)
        ld h,(ix+IDE_START_POLLS+1)
        pop ix
        jp _zx_ide_wait_data
@invalid:
        ld l,1
@done:
        pop ix
        ret
