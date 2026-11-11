        MODULE baseconf_console_scroll
PUBLIC generic_console_scrollup
EXTERN _bc__console_scroll
SECTION code_clib
; Generic-console adapter: call console_scroll(), then return A=0, Z=1, CF=0.
; No arguments; AF/BC/DE/HL volatile, IX/IY preserved by the backend.
; The backend owns its lease; its status is not reported through A or carry.
generic_console_scrollup:
        call _bc__console_scroll
        xor a
        ret
