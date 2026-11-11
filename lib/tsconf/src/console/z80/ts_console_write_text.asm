        MODULE ts_console_text
SECTION code_clib
PUBLIC ts_console_write_text
EXTERN ts_draw_base
EXTERN ts_console_text_attribute

; Write the two bytes of a native TSConf text cell.
;
; screen[256*row+column] = code;
; screen[256*row+column+128] = attr;
;
; A=code, B=row, C=column. Mapped 16 KiB page and valid cell required.
; AF/E/HL volatile, BC/D/IX/IY preserved.
ts_console_write_text:
        ld e,a
        ld a,(ts_draw_base)
        or b
        ld h,a
        ld l,c
        ld (hl),e
        set 7,l
        call ts_console_text_attribute
        ld (hl),a
        ret
