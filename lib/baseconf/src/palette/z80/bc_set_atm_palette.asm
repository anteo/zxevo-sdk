        MODULE bc_set_atm_palette
SECTION code_clib
PUBLIC _bc_set_atm_palette
EXTERN bc__palette_encode_rgb222_regs
EXTERN bc__palette_write_atm

; Set the current-beam ATM RGB222 entry. Model:
;
; if (index >= 16 || (r | g | b) >= 4) return ZX_INVALID_ARGUMENT;
; bf = IN(0x00bf);
; if (bf & 0x20) return ZX_UNAVAILABLE;
; return write_atm_palette(bf, 0, encode_rgb222(r, g, b));
;
; SDCC index:8 at SP+2 and r/g/b by value at SP+3/+4/+5. Status in L.
; Preserve IX/IY, clobber AF/BC/DE/HL. The caller times the raster write.
; The index is a range-checked assertion about the expected beam color.
_bc_set_atm_palette:
        ld hl,2
        add hl,sp
        ld a,(hl)
        cp 16
        jr nc,@invalid
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld c,(hl)
        ld a,e
        or d
        or c
        cp 4
        jr nc,@invalid

        ld l,c                       ; keep blue across BF port selection
        ld bc,00BFh
        in h,(c)
        ld c,l
        bit 5,h
        ld l,3                       ; ZX_UNAVAILABLE in RGB444 mode
        ret nz
        call bc__palette_encode_rgb222_regs
        ld c,a                       ; encoded byte, B = 0 selects RGB222
        ld a,h                       ; encoder preserves the saved BF
        jp bc__palette_write_atm
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
