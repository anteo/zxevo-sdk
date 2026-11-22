        MODULE ts_fat_rewind
EXTERN ts__fat_call
SECTION code_clib
PUBLIC _ts_fat_rewind

; SEEK0 resets the cursor of the open file. Common ROM ABI and mappings.
_ts_fat_rewind:
        ld a,2
        jp ts__fat_call
