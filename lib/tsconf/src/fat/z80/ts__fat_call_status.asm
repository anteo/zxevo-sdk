        MODULE ts__fat_call_status
EXTERN ts__fat_call
SECTION code_clib
PUBLIC ts__fat_call_status

; Convert the ROM's Z success flag to ZX_OK or ZX_IO_ERROR in L.
ts__fat_call_status:
        call ts__fat_call
        ld l,0
        ret z
        ld l,8
        ret
