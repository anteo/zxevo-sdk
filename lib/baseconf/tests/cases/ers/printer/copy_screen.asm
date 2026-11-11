        MODULE printer_test_copy_screen

SECTION code_user
PUBLIC _printer_test_copy_screen

; Call BASIC COPY, which invokes ERS 43h and resumes in BASIC's printer cleanup.
; The test supplies the printer flag in the BASIC system variables at $5C3A.
; No arguments or return value. Preserve IX/IY and leave interrupts disabled.
_printer_test_copy_screen:
        push ix
        push iy
        ld iy,05c3ah
        call 00each
        di
        pop iy
        pop ix
        ret
