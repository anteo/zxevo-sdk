        MODULE bc__video_strided_copy_rows

SECTION code_clib
PUBLIC bc__video_strided_copy_rows

; Forward copy of the active bytes in each strided row. Model:
;
; while (rows-- && length) {
;     copy_forward(source, destination, length);
;     source += length + gap; destination += length + gap;
; }
;
; HL = source, DE = destination, A = rows, B = gap, C = length.
; Caller supplies valid CPU ranges and forward-safe overlap. Preserve IX/IY,
; clobber AF/BC/DE/HL. One temporary word saves gap/length while BC is used
; for LDIR or address arithmetic. A counts rows and LDIR preserves it.
bc__video_strided_copy_rows:
        or a
        ret z
        inc c
        dec c
        ret z                        ; avoid the 64 KiB LDIR count
@row:
        push bc
        ld b,0
        ldir
        pop bc
        dec a
        ret z
        push bc
        ld c,b
        ld b,0
        add hl,bc
        ex de,hl
        add hl,bc
        ex de,hl
        pop bc
        jr @row
