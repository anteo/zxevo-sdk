        MODULE ts_spi_read_config
SECTION code_clib
PUBLIC _ts_spi_read_config

; Read SPI status from 77h into L. Clobber A/L.
_ts_spi_read_config:
        in a,(77h)
        ld l,a
        ret
