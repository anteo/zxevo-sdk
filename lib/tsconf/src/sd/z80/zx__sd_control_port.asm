        MODULE zx__sd_control_port
SECTION code_clib
PUBLIC _zx__sd_control_port

; TSConf selects SD1 at 0077h. Fastcall HL=valid output, L=ZX_OK.
_zx__sd_control_port:
        ld (hl),0
        ld l,0
        ret
