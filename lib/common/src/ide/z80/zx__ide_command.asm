        MODULE zx__ide_command
SECTION code_clib
PUBLIC _zx__ide_command
EXTERN zx__ide_wait_bus
EXTERN zx__ide_wait_idle

; Issue an ATA command that takes no LBA after selecting device 0.
;
; if ((status = wait_bus(polls)) != ZX_OK) return status;
; select_device(0xe0);
; if ((status = wait_idle(polls)) != ZX_OK) return status;
; issue(command);
; return ZX_OK;
;
; SDCC command at SP+2, poll limit at SP+3, result in L. Preserve IX/IY.
; Saves command and poll count across waits. Caller checks the command result.
_zx__ide_command:
        ld hl,2
        add hl,sp
        ld a,(hl)
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ex de,hl
        push af
        push hl
        call zx__ide_wait_bus
        ld a,l
        or a
        pop de
        jr nz,@done
        ld bc,80D0h
        ld a,0E0h
        out (c),a
        ex de,hl
        call zx__ide_wait_idle
        ld a,l
        or a
        jr nz,@done
        pop af
        ld c,0F0h
        out (c),a
        ret
@done:
        pop af
        ret
