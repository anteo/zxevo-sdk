        MODULE ts_fat_mount_sd
SECTION code_clib
PUBLIC _ts_fat_mount_sd
EXTERN ts__fat_call_status

; Mount SD1 through CRTSTREAM and return the ROM result as a status.
; SDCC classic: no arguments, L = status. Save IX and IY across the RST.
; ROM page 0 in W0, caller stack outside W2, and workspace F7h reserved.
; Clobbers AF, BC, DE, HL and the alternate bank. Returns with INT disabled.
_ts_fat_mount_sd:
        ld bc,0
        ld a,20h
        jp ts__fat_call_status
