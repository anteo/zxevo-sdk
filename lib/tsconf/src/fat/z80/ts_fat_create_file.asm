        MODULE ts_fat_create_file
SECTION code_clib
PUBLIC _ts_fat_create_file
EXTERN ts__fat_call_status

; Create a file of the given length and open it for sector I/O.
;
; if (!name || name->type != FILE || !size) return INVALID_ARGUMENT;
; return tsbios_mkfile(name, size).z ? OK : IO_ERROR;
;
; SDCC name pointer at SP+2, size at SP+4. Pass name in HL and size in
; BC:DE (high:low), return L. Name resident outside W2. Common ROM mappings.
; Clobbers AF/BC/DE/HL and alternate registers, preserves IX/IY.
_ts_fat_create_file:
        ld hl,2
        add hl,sp
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        push de                      ; hold the name while loading the size
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld c,(hl)
        inc hl
        ld b,(hl)
        pop hl
        ld a,h
        or l
        jr z,@invalid
        ld a,(hl)
        or a
        jr nz,@invalid
        ld a,b
        or c
        or d
        or e
        jr z,@invalid
        ld a,12h
        jp ts__fat_call_status
@invalid:
        ld l,1
        ret
