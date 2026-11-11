        MODULE zx_fdd_reg_access
SECTION code_clib
PUBLIC _zx_fdd_reg_read
PUBLIC _zx_fdd_reg_write

; Read one byte from the selected VG93 register.
;
; if (reg > 3 || !value) return ZX_INVALID_ARGUMENT;
; *value = in(0xff1f | (reg << 5));
; return ZX_OK;
;
; SDCC reg at SP+2, output pointer at SP+3. Status in L.
; Beta Disk ports must be open and the selected drive physical.
; Clobber AF/BC/DE/HL, preserve IX/IY.
_zx_fdd_reg_read:
        ld hl,2
        add hl,sp
        ld a,(hl)
        cp 4
        jr nc,invalid
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld h,a
        ld a,d
        or e
        jr z,invalid
        ld a,h
        call register_port
        in a,(c)
        ld (de),a
        jr success

; Write a byte to the selected VG93 register.
;
; if (reg > 3) return ZX_INVALID_ARGUMENT;
; out(0xff1f | (reg << 5), value);
; return ZX_OK;
;
; SDCC reg at SP+2 and value at SP+3. Same preconditions, result and clobbers.
_zx_fdd_reg_write:
        ld hl,2
        add hl,sp
        ld a,(hl)
        cp 4
        jr nc,invalid
        inc hl
        call register_port
        ld a,(hl)
        out (c),a
success:
        ld l,0                      ; ZX_OK
        ret
invalid:
        ld l,1                      ; ZX_INVALID_ARGUMENT
        ret

; A = 0..3. Rotate the register index into A5/A6 and add 1Fh.
; Return BC = FF1Fh, FF3Fh, FF5Fh or FF7Fh. Preserve DE/HL.
; VG93 decodes the low byte. FFh avoids the Fuller Audio Box aliases.
register_port:
        rrca
        rrca
        rrca
        or 1Fh
        ld c,a
        ld b,0ffh
        ret
