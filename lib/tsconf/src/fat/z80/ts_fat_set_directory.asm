        MODULE ts_fat_set_directory
SECTION code_clib
PUBLIC _ts_fat_set_directory
EXTERN ts__fat_call

; Find a directory entry and select it as the current directory.
;
; if (!name || name->type != DIRECTORY) return INVALID_ARGUMENT;
; if (!tsbios_fentry(name).z) return IO_ERROR;
; tsbios_setdir();
; return OK;
;
; Fastcall HL = name record outside W2, result in L. Common ROM mappings.
; Clobbers AF/BC/DE/HL and alternate registers, preserves IX/IY.
_ts_fat_set_directory:
        ld a,h
        or l
        jr z,@invalid
        ld a,(hl)
        cp 10h
        jr nz,@invalid
        ld a,10h
        call ts__fat_call
        jr nz,@missing
        ld a,11h
        call ts__fat_call
        ld l,0
        ret
@invalid:
        ld l,1
        ret
@missing:
        ld l,8
        ret
