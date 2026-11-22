        MODULE zx_fdd_reg_read
EXTERN ts__fdd_register_port
SECTION code_clib
PUBLIC _zx_fdd_reg_read

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
        jr nc,@invalid
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld h,a
        ld a,d
        or e
        jr z,@invalid
        ld a,h
        call ts__fdd_register_port
        in a,(c)
        ld (de),a
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
