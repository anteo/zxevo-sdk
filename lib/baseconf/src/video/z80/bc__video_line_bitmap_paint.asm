IFDEF BASECONF_VIDEO_PRIMITIVE_BITMAP
        MODULE bc__video_line_bitmap_paint
SECTION code_clib
PUBLIC bc__video_line_bitmap_paint

; IX operation +10 (SET=0, CLEAR=1, XOR=2).
; Return B = full-byte AND mask, C = full-byte XOR bits. Preserve HL/DE/IX/IY.
;
; Returns the byte masks that implement a bitmap set, clear or toggle
; operation.
;
; Model:
;
; (AND,XOR) = operation==SET ? (0,0xff) : operation==CLEAR ? (0,0) : (0xff,0xff);
;
; For each complete byte: new=(old&AND)^XOR. No memory access. Operation
; is already validated 0..2; ABI/preservation is given above.
bc__video_line_bitmap_paint:
        ld b,0
        ld c,0
        ld a,(ix+10)
        cp 1
        ret z
        dec c
        or a
        ret z
        dec b
        ret
ENDIF
