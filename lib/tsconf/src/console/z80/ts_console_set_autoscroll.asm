        MODULE ts_console_set_autoscroll
SECTION code_clib
PUBLIC _ts_console_set_autoscroll
EXTERN ts__console_scroll
EXTERN ts__console_scroll_callback

; Install or clear the bottom-row scroll action. Fastcall L=enable.
; Keep the renderer out of applications which never opt in.
_ts_console_set_autoscroll:
        ld a,l
        or a
        ld hl,0
        jr z,@store
        ld hl,ts__console_scroll
@store:
        ld (ts__console_scroll_callback),hl
        ret
