        MODULE ts_joystick_read
SECTION code_clib
PUBLIC _ts_joystick_read

; Read the Kempston buttons. DOS and FDDVirt.D7 must be clear.
; Return the button mask in L. BC and flags clobbered.
_ts_joystick_read:
        ld bc,001Fh
        in l,(c)
        ret
