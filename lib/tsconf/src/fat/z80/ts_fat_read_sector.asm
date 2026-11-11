        MODULE ts_fat_read_sector
SECTION code_clib
PUBLIC _ts_fat_read_sector
PUBLIC _ts_fat_write_sector
EXTERN ts__fat_call

; Read the next sector into physical RAM through TS-FAT READ512.
;
; tsbios_read512(1, page, offset);
;
; SDCC classic: page at SP+2, offset at SP+3, no return value. ROM takes
; B = 1, C = physical page, DE = offset. Save IX and IY across the RST.
; ROM page 0 in W0, caller stack outside W2, F7h reserved. The sector
; must fit in its physical page and the starting offset must be even.
; Clobbers AF, BC, DE, HL and the alternate bank. Returns with INT disabled.
_ts_fat_read_sector:
        xor a
        jr ts__fat_sector

; Write the next sector from a physical RAM page through TS-FAT WRITE512.
;
; tsbios_write512(1, page, offset);
;
; Same ABI, mapping and register requirements as READ512. Caller supplies
; an existing writable file and an offset within its allocated chain.
_ts_fat_write_sector:
        ld a,1
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
