        MODULE ts_console_zx_attribute
SECTION code_clib
PUBLIC ts_console_zx_attribute
EXTERN zx__ink
EXTERN zx__encode_attribute

; Encode the shared colors with TSConf's ZX FLASH bit.
; Return A=attribute. AF/DE volatile, BC/HL/IX/IY preserved.
ts_console_zx_attribute:
        ld de,(zx__ink)
        call zx__encode_attribute
        ld e,a
        ld a,(ts_console_zx_flash)
        or e
        ret

SECTION bss_clib
PUBLIC ts_console_zx_flash
ts_console_zx_flash: defb 0
