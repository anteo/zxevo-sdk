        MODULE zx__rtc_read_scoped
EXTERN bc__rtc_read_scoped_regs
SECTION code_clib
PUBLIC _zx__rtc_read_scoped

; Read one register inside the caller's active RTC scope.
_zx__rtc_read_scoped:
        ld a,l
        jp bc__rtc_read_scoped_regs
