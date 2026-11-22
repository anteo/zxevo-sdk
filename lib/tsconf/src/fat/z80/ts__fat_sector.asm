        MODULE ts__fat_sector
EXTERN ts__fat_call
SECTION code_clib
PUBLIC ts__fat_sector
ts__fat_sector:
        ld hl,2
        add hl,sp
        ld c,(hl)
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld b,1
        jp ts__fat_call
