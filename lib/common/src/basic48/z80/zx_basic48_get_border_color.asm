        MODULE zx_basic48_get_border_color
SECTION code_clib
PUBLIC _zx_basic48_get_border_color
EXTERN __SYSVAR_BORDCR

; Read BASIC's saved border from bits 3..5 of BORDCR. Return color in L.
_zx_basic48_get_border_color:
        ld a,(__SYSVAR_BORDCR)
        rrca
        rrca
        rrca
        and 7
        ld l,a
        ret
