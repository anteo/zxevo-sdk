        MODULE ts_spi_select
SECTION code_clib
PUBLIC _ts_spi_select

; Select the shared SPI target. Fastcall L = select byte, clobber A.
_ts_spi_select:
        ld a,l
        out (77h),a
        ret
