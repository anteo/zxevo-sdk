        MODULE zx__rtc_write_scoped
EXTERN bc__rtc_write_scoped_regs
SECTION code_clib
PUBLIC _zx__rtc_write_scoped

; Load index and value from the SDCC stack inside an active RTC scope.
_zx__rtc_write_scoped:
        ld hl,2
        add hl,sp
        ld a,(hl)
        inc hl
        ld e,(hl)
        jp bc__rtc_write_scoped_regs
