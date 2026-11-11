        MODULE ts_fat_position
SECTION code_clib
PUBLIC _ts_fat_rewind
PUBLIC _ts_fat_skip_sectors
EXTERN ts__fat_call

; SEEK0 resets the cursor of the open file. Common ROM ABI and mappings.
_ts_fat_rewind:
        ld a,2
        jp ts__fat_call

; SKIP512 advances the open file by fastcall L sectors. Zero is a no-op.
;
; if (count) tsbios_skip512(count);
;
; Clobbers AF/BC/DE/HL and alternate registers, preserves IX/IY.
_ts_fat_skip_sectors:
        ld a,l
        or a
        ret z
        ld b,a
        ld a,4
        jp ts__fat_call
