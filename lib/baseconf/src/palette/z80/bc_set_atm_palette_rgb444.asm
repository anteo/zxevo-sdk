        MODULE bc_set_atm_palette_rgb444
SECTION code_clib
PUBLIC _bc_set_atm_palette_rgb444
EXTERN bc__palette_encode_rgb222_regs
EXTERN bc__palette_write_atm
EXTERN _bc_palette_rgb444_cache
EXTERN _bc_palette_rgb444_valid

; Set the current-beam ATM RGB444 entry. Model:
;
; if (index >= 16 || (r | g | b) >= 16) return ZX_INVALID_ARGUMENT;
; bf = IN(0x00bf);
; if (!(bf & 0x20)) return ZX_UNAVAILABLE;
; data = encode_rgb222(r >> 2, g >> 2, b >> 2);
; address_high = encode_rgb222(r, g, swap_low_two_bits(b));
; write_atm_palette(bf, address_high, data);
; cache[index] = {r, g, b}; valid[index] = 1;
; return ZX_OK;
;
; SDCC index:8 at SP+2 and r/g/b by value at SP+3/+4/+5. Status in L.
; Preserve IX/IY, clobber AF/BC/DE/HL. Caller times the beam write. H saves
; BF across both encodes. Two temporary words retain the original RGB bytes
; across the first encode. The index addresses the software cache only.
_bc_set_atm_palette_rgb444:
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
        cp 16
        jr nc,@invalid

        ld l,c
        ld bc,00BFh
        in h,(c)
        ld c,l
        bit 5,h
        ld l,3                       ; ZX_UNAVAILABLE without RGB444 mode
        ret z

        push de
        push bc
        srl e
        srl e
        srl d
        srl d
        srl c
        srl c
        call bc__palette_encode_rgb222_regs
        pop bc
        pop de
        ld b,a                       ; encoder preserves B on the second call

        ; RGB444 places B1 in A13 and B0 in A8. Swapping the blue input bits
        ; maps them into the encoder's output bits 5 and 0 respectively.
        ld a,c
        and 2
        rrca
        bit 0,c
        jr z,@blue_ready
        or 2
@blue_ready:
        ld c,a
        call bc__palette_encode_rgb222_regs
        ld c,b
        ld b,a
        ld a,h
        call bc__palette_write_atm

        ; Copy the original three RGB bytes before setting the validity flag.
        ; A holds the cache index across LDIR. Its final BC is zero.
        ld hl,2
        add hl,sp
        ld a,(hl)
        inc hl
        push hl                      ; original color argument
        ld c,a
        ld b,0
        ld h,b
        ld l,c
        add hl,hl
        add hl,bc                    ; index * sizeof(bc_rgb444_t)
        ld de,_bc_palette_rgb444_cache
        add hl,de
        ex de,hl
        pop hl
        ld bc,3
        ldir
        ld c,a
        ld hl,_bc_palette_rgb444_valid
        add hl,bc
        ld (hl),1
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
