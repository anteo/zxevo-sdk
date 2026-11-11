        MODULE baseconf_console_ioctl

PUBLIC generic_console_ioctl

SECTION code_clib
; Return carry for target-specific generic console requests. The z88dk
; wrapper handles its common requests. Use zx_console_set_font for fonts.
; Preserve registers. A=request, DE=argument pointer.
generic_console_ioctl:
        scf
        ret
