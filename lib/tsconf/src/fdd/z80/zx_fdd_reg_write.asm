        MODULE zx_fdd_reg_write
EXTERN ts__fdd_register_port
SECTION code_clib
PUBLIC _zx_fdd_reg_write

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
        jr nc,@invalid
        inc hl
        call ts__fdd_register_port
        ld a,(hl)
        out (c),a
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
