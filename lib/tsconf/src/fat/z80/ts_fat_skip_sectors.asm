        MODULE ts_fat_skip_sectors
EXTERN ts__fat_call
SECTION code_clib
PUBLIC _ts_fat_skip_sectors

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
