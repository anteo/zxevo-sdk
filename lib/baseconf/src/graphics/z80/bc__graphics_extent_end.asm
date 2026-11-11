        MODULE bc__graphics_extent_end
SECTION code_graphics
PUBLIC bc__graphics_extent_end

; HL=origin, DE=positive size. Return min(origin+size-1,32767) in HL.
; Positive overflow is beyond the screen. Preserve BC/IX/IY, clobber AF/DE/HL.
bc__graphics_extent_end:
        dec de
        or a
        adc hl,de
        ret po
        ld hl,7FFFh
        ret
