        MODULE zx_ide_wait
SECTION code_clib
PUBLIC _zx_ide_wait_data
PUBLIC _zx_ide_wait_complete
PUBLIC zx__ide_wait_bus
PUBLIC zx__ide_wait_idle

; Poll Nemo alternate status for data, completion, or a safe command boundary.
;
; while (polls--) {
;     status = IN(0x80c8);
;     if (before_select && (status == 0xff || status == 0)) return ZX_OK;
;     if (status == 0xff) return ZX_UNAVAILABLE;
;     if (!status || (status & BSY)) continue;
;     if (before_select) { if (!(status & DRQ)) return ZX_OK; continue; }
;     if (check_error && (status & (DF | ERR))) return ZX_IO_ERROR;
;     if ((status & mask) == expected) return ZX_OK;
; }
; return ZX_TIMEOUT;
;
; The idle phase ignores errors left by a previous command. The alternate
; status read leaves the ATA interrupt pending. The completion entry reads
; primary status after the wait to acknowledge it. SDCC HL = polls, status in L.
; Preserve IX/IY, clobber AF/BC/DE/HL.
_zx_ide_wait_data:
        ld de,0808h
        jr zx__ide_wait_regs
_zx_ide_wait_complete:
        ld de,0008h
        call zx__ide_wait_regs
        ld a,l
        or a
        ret nz
        ld c,0F0h
        in a,(c)
        ret
zx__ide_wait_idle:
        ld de,4048h
        jr zx__ide_wait_regs
zx__ide_wait_bus:
        ld de,8008h                  ; D.7 selects the pre-selection phase
zx__ide_wait_regs:
        ld a,h
        or l
        jr z,@invalid
        ld bc,80C8h
@poll:
        in a,(c)
        cp 0FFh
        jr z,@floating
        or a
        jr z,@empty
        jp m,@next                   ; BSY makes the remaining flags undefined
        bit 7,d
        jr nz,@bus_idle
        bit 6,d
        jr nz,@phase
        bit 0,a
        jr nz,@error
        bit 5,a
        jr nz,@error
@phase:
        and e
        cp d
        jr z,@ok
        jr @next
@bus_idle:
        and e
        jr z,@ok
@next:
        dec hl
        ld a,h
        or l
        jr nz,@poll
        ld l,7                       ; ZX_TIMEOUT
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
@empty:
        bit 7,d
        jr nz,@ok
        jr @next
@floating:
        bit 7,d
        jr nz,@ok
        ld l,3                       ; ZX_UNAVAILABLE
        ret
@error:
        ld l,8                       ; ZX_IO_ERROR
        ret
@ok:
        ld l,0                       ; ZX_OK
        ret
