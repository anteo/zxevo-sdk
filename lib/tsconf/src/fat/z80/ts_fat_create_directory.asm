        MODULE ts_fat_create_directory
SECTION code_clib
PUBLIC _ts_fat_create_directory
EXTERN ts__fat_call_status

; MKDIR takes a name string, unlike FENTRY which takes a record.
; Fastcall HL = resident name outside W2, result L. Common ROM mappings.
; Clobbers AF/BC/DE/HL and alternate registers, preserves IX/IY.
_ts_fat_create_directory:
        ld a,h
        or l
        jr z,@invalid
        ld a,(hl)
        or a
        jr z,@invalid
        ld a,13h
        jp ts__fat_call_status
@invalid:
        ld l,1
        ret
