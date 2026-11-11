        MODULE ts_fat_open
SECTION code_clib
PUBLIC _ts_fat_open
EXTERN ts__fat_call

; Search the mounted directory and return its file length on success.
;
; if (!name || !size || name->type != FILE) return INVALID_ARGUMENT;
; result = tsbios_fentry(name);
; if (!result.z) return IO_ERROR;
; *size = result.dehl;
; return OK;
;
; SDCC classic: name at SP+2, size at SP+4, result in L. Pass name in HL.
; Save the size pointer, IX and IY on the caller stack before the RST.
; ROM page 0 in W0, code, name and caller stack outside W2, F7h reserved.
; The ROM's trampoline restores W2 and SP with Z intact. Clobbers AF,
; BC, DE, HL and the alternate bank. Returns with INT disabled.
_ts_fat_open:
        ld hl,2
        add hl,sp
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld c,(hl)
        inc hl
        ld b,(hl)
        ld a,b
        or c
        jr z,@invalid
        ld a,d
        or e
        jr z,@invalid
        ex de,hl
        ld a,(hl)
        or a
        jr nz,@invalid
        push bc
        ld a,10h
        call ts__fat_call
        pop bc
        jr nz,@missing

        ; The ROM returns the low word in HL and the high word in DE.
        ld a,l
        ld (bc),a
        inc bc
        ld a,h
        ld (bc),a
        inc bc
        ld a,e
        ld (bc),a
        inc bc
        ld a,d
        ld (bc),a
        ld l,0
        ret
@missing:
        ld l,8                       ; ZX_IO_ERROR
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
