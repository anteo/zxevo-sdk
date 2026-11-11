        MODULE baseconf_console_stdout
SECTION code_clib
PUBLIC fputc_cons_native
EXTERN fputc_cons_generic

; Use the classic console's cursor, scrolling and control sequences.
defc fputc_cons_native = fputc_cons_generic
