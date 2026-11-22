        MODULE ts_zifi_read
EXTERN ts__zifi_transfer
SECTION code_clib
PUBLIC _ts_zifi_read

; Read the available FIFO prefix. A=0 selects input for the shared transfer.
_ts_zifi_read:
        xor a
        jp ts__zifi_transfer
