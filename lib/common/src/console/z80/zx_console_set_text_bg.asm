        MODULE zx_console_set_text_bg

SECTION code_clib
PUBLIC _zx_console_set_text_bg

; Set the shared console background mode. Fastcall L=mode, return status in L.
; AF/L volatile, IX/IY preserved. Invalid modes leave the setting unchanged.
_zx_console_set_text_bg:
        ld a,l
        cp 2
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret nc
        ld (_zx__console_text_bg),a
        ld l,0                       ; ZX_OK
        ret

SECTION bss_clib
PUBLIC _zx__console_text_bg
_zx__console_text_bg: defb 0          ; ZX_TEXT_OPAQUE
