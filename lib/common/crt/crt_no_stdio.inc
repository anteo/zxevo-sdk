; Keep the classic runtime selector from linking the console when stdio is off.
; Respect an explicit console redirect or ANSI terminal selection.
; The stub preserves all registers.
IF CRT_ENABLE_STDIO = 0 && !DEFINED_fputc_cons && !NEED_ansiterminal
        defc DEFINED_fputc_cons = 1
        SECTION code_clib
        PUBLIC fputc_cons
fputc_cons:
        ret
ENDIF
