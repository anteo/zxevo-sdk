        MODULE ts_zifi_write
EXTERN ts__zifi_transfer
SECTION code_clib
PUBLIC _ts_zifi_write
_ts_zifi_write:
        ld a,1
        jp ts__zifi_transfer
