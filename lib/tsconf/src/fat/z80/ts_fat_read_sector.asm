        MODULE ts_fat_read_sector
EXTERN ts__fat_sector
SECTION code_clib
PUBLIC _ts_fat_read_sector

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
        jp ts__fat_sector
