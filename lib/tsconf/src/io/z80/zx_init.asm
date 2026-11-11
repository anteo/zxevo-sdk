        MODULE zx_init
SECTION code_clib
PUBLIC _zx_init

; TSConf has no global setup. Return ZX_OK in L without touching hardware.
_zx_init:
        ld l,0
        ret
