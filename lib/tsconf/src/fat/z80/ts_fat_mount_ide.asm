        MODULE ts_fat_mount_ide
SECTION code_clib
PUBLIC _ts_fat_mount_ide
EXTERN ts__fat_call_status

; Mount Nemo master (0) or slave (1) through CRTSTREAM.
;
; if (drive > 1) return INVALID_ARGUMENT;
; return tsbios_crtstream(drive + 1).z ? OK : IO_ERROR;
;
; Fastcall L = drive, result L. TS-BIOS in W0 with stack outside W2,
; F7h reserved and the frame IRQ source enabled for ROM drive detection.
; Clobbers AF/BC/DE/HL and alternate registers, preserves IX/IY.
_ts_fat_mount_ide:
        ld a,l
        cp 2
        jr nc,@invalid
        inc a
        ld b,a
        ld c,0
        ld a,20h
        jp ts__fat_call_status
@invalid:
        ld l,1
        ret
