        MODULE ts_fat_write_sector
EXTERN ts__fat_sector
SECTION code_clib
PUBLIC _ts_fat_write_sector

; Write the next sector from a physical RAM page through TS-FAT WRITE512.
;
; tsbios_write512(1, page, offset);
;
; Same ABI, mapping and register requirements as READ512. Caller supplies
; an existing writable file and an offset within its allocated chain.
_ts_fat_write_sector:
        ld a,1
        jp ts__fat_sector
