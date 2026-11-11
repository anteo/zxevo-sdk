        MODULE ts_spi_write
SECTION code_clib
PUBLIC _ts_spi_write

; Shift one byte through the SPI pipeline. Fastcall L = byte, clobber A.
_ts_spi_write:
        ld a,l
        out (57h),a
        ret
