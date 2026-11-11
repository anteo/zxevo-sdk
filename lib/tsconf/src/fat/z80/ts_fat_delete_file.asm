        MODULE ts_fat_delete_file
SECTION code_clib
PUBLIC _ts_fat_delete_file
EXTERN ts__fat_call_status

; DELFILE removes an ordinary file, rejecting directory records.
; Fastcall HL = resident name record outside W2, result L. Common ROM mappings.
; Clobbers AF/BC/DE/HL and alternate registers, preserves IX/IY.
_ts_fat_delete_file:
        ld a,h
        or l
        jr z,@invalid
        ld a,(hl)
        or a
        jr nz,@invalid
        ld a,14h
        jp ts__fat_call_status
@invalid:
        ld l,1
        ret
