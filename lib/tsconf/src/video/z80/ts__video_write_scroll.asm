        MODULE ts__video_write_scroll
SECTION code_clib
PUBLIC ts__video_write_scroll
; Write the low byte and bit 8 of each scroll coordinate to four consecutive
; TS registers. A = first register + 1 for OUTI. SDCC x at SP+2, y at SP+4.
; The caller serializes writes and chooses raster timing. Clobbers AF/BC/HL.
ts__video_write_scroll:
        ld hl,2
        add hl,sp
        ; OUTI uses B after decrementing it. Each entry supplies first + 1.
        ld b,a
        ld c,0afh
        outi
        inc b
        ld a,(hl)
        and 1
        out (c),a
        inc hl
        inc b
        inc b
        outi
        inc b
        ld a,(hl)
        and 1
        out (c),a
        ret
