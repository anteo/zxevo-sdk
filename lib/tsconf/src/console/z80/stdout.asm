        MODULE ts_console_stdout
SECTION code_clib
PUBLIC fputc_cons_native
EXTERN _zx_console_putc

; Both entry points take the character byte at SP+2 and preserve IX/IY.
defc fputc_cons_native = _zx_console_putc
