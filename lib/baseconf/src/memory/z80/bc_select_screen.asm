        MODULE bc_select_screen
SECTION code_clib
PUBLIC _bc_select_screen
EXTERN _bc_mem_initialized
EXTERN bc__mem_readback_register_regs

; Select the displayed screen through 7FFD bit 3 and return a status.
;
; if (screen > 1) return ZX_INVALID_ARGUMENT;
; if (!initialized) return ZX_NOT_INITIALIZED;
; paging = readback(0x0a);
; if (((paging >> 3) & 1) == screen) return ZX_OK;
; if ((readback(0x0b) & 4) && (paging & 0x20)) return ZX_BUSY;
; out(0x7ffd, (paging & ~8) | (screen << 3));
; return ZX_OK;
;
; SDCC screen byte at SP+2, status in L. D/E retain the original 7FFD
; byte and new bit across readback. Preserve IX/IY, clobber AF/BC/DE/HL.
_bc_select_screen:
        ld hl,2
        add hl,sp
        ld a,(hl)
        cp 2
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret nc
        rlca
        rlca
        rlca
        ld e,a
        ld a,(_bc_mem_initialized)
        or a
        ld l,4                       ; ZX_NOT_INITIALIZED
        ret z
        ld b,0Ah
        call bc__mem_readback_register_regs
        ld d,l
        ld a,d
        xor e
        and 8
        ld l,0                       ; ZX_OK if already displayed
        ret z
        ld b,0Bh
        call bc__mem_readback_register_regs
        bit 2,l
        jr z,@write
        bit 5,d
        ld l,2                       ; ZX_BUSY while locked in 128K mode
        ret nz
@write:
        ld a,d
        and 0F7h
        or e
        ld bc,7FFDh
        out (c),a
        ld l,0                       ; ZX_OK
        ret
