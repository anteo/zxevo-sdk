        MODULE bc_get_atm_palette_rgb444
SECTION code_clib
PUBLIC _bc_get_atm_palette_rgb444
EXTERN _bc_palette_rgb444_cache
EXTERN _bc_palette_rgb444_valid

; Copy a cached RGB444 entry to the caller's buffer. Errors leave it untouched.
; Model:
;
; if (index >= 16 || !color) return ZX_INVALID_ARGUMENT;
; if (!valid[index]) return ZX_UNAVAILABLE;
; *color = cache[index];
; return ZX_OK;
;
; SDCC index:8 at SP+2, color pointer at SP+3. Status in L.
; Preserve IX/IY, clobber AF/BC/DE/HL. No local stack storage.
_bc_get_atm_palette_rgb444:
        ld hl,2
        add hl,sp
        ld c,(hl)
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ld a,c
        cp 16
        ret nc
        ld a,d
        or e
        ret z

        ld b,0
        ld hl,_bc_palette_rgb444_valid
        add hl,bc
        ld a,(hl)
        or a
        ld l,3                       ; ZX_UNAVAILABLE
        ret z

        ld h,b
        ld l,c
        add hl,hl
        add hl,bc                    ; index * sizeof(bc_rgb444_t)
        ld bc,_bc_palette_rgb444_cache
        add hl,bc
        ld bc,3
        ldir
        ld l,c                       ; ZX_OK (LDIR leaves BC = 0)
        ret
