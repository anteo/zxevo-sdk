        MODULE ts__fat_call
SECTION code_clib
PUBLIC ts__fat_call
PUBLIC ts__fat_call_status
EXTERN ts__cpu_speed
EXTERN ts__cache_mask

; Invoke the selected TS-BIOS FAT service, preserving SDCC's IX and IY.
; A = function, remaining registers per ROM ABI. Clobbers AF/BC/DE/HL and
; alternate registers. The return flags are those left by the ROM.
; Requires TS-BIOS in W0, caller stack outside W2 and F7h reserved.
; TS-BIOS writes SysConfig=02h even when the FAT service fails.
ts__fat_call:
        push ix
        push iy
        rst 10h
        push af
        ld a,2
        ld (ts__cpu_speed),a
        xor a
        ld (ts__cache_mask),a
        pop af
        pop iy
        pop ix
        ret

; Convert the ROM's Z success flag to ZX_OK or ZX_IO_ERROR in L.
ts__fat_call_status:
        call ts__fat_call
        ld l,0
        ret z
        ld l,8
        ret
