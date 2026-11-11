        MODULE ts_fat_set_root
SECTION code_clib
PUBLIC _ts_fat_set_root
EXTERN ts__fat_call

; SETROOT selects the root directory and resets the last entry. Common ROM ABI.
_ts_fat_set_root:
        ld a,15h
        jp ts__fat_call
