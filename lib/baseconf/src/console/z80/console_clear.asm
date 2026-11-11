        MODULE baseconf_console_clear_hook
PUBLIC generic_console_cls
EXTERN _zx_console_clear
SECTION code_clib
; Generic-console adapter: call console_clear(), then return A=0, Z=1, CF=0.
; No arguments; AF/BC/DE/HL volatile, IX/IY preserved by the backend.
; The backend owns its lease; its status is not reported through A or carry.
generic_console_cls:
        call _zx_console_clear
        xor a
        ret
