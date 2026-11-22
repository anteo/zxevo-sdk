        MODULE bc__font_upload_validate
EXTERN bc__font_upload_overlap
EXTERN bc__font_upload_range
SECTION code_clib
PUBLIC bc__font_upload_validate

; HL = font, DE = destination. Preserve both; CF = invalid CPU range.
; An aligned 2 KiB destination in W1..W3 cannot wrap or cross a window.
;
; Checks that the source and aligned destination are valid, separate CPU
; ranges for a 2 KiB font upload.
;
; Model:
;
; invalid=!valid_2k(font) || destination<0x4000 ||
; (destination&0x7ff)!=0 || overlap_2k(font,destination).
;
; Checks CPU ranges only; caller guarantees the current physical mappings and
; absence of aliases. AF/BC volatile; HL/DE/IX/IY preserved; CF=invalid.
bc__font_upload_validate:
        call bc__font_upload_range
        ret c
        ld a,d
        and 7
        or e
        jr nz,@invalid
        ld a,d
        cp 40h
        jr c,@invalid
        jp bc__font_upload_overlap
@invalid:
        scf
        ret
