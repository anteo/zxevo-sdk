        MODULE ts_spi_read_previous
SECTION code_clib
PUBLIC _ts_spi_read_previous

; Read the preceding SPI response and clock FFh. Return L, clobber A/L.
_ts_spi_read_previous:
        in a,(57h)
        ld l,a
        ret
