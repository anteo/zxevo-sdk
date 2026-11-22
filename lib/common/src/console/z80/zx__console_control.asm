        MODULE zx__console_control
EXTERN zx__console_newline
SECTION code_clib
PUBLIC zx__console_control

; Apply CR, LF or BS. Other controls leave the cursor unchanged.
; A=code, BC=column/row, D=rows. Return cursor in BC. Clobber AF only.
zx__console_control:
        cp 10
        jp z,zx__console_newline
        cp 13
        jr z,@carriage_return
        cp 8
        ret nz
        ld a,c
        or a
        ret z
        dec c
        ret
@carriage_return:
        ld c,0
        ret
