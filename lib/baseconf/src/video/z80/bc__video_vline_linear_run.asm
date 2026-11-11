IFDEF BASECONF_VIDEO_PRIMITIVE_LINEAR
        MODULE bc__video_vline_linear_run
SECTION code_clib
PUBLIC bc__video_vline_linear_run

; HL = first CPU address, B = row count (1..200), D = AND, E = XOR.
; ATM320/640 planes have a forty-byte row stride. Preserve IX/IY.
;
; Paints the selected bits down a column of a linear bitmap or packed plane,
; advancing by 40 bytes per row.
;
; Model:
;
; for (row=0; row<count; ++row) { *address=(*address&AND)^XOR; address+=40; }
;
; Uses the register ABI above; no lease acquisition or bounds check.
; AF/B/HL volatile; C/DE/IX/IY preserved. Avoid advancing past the final row.
bc__video_vline_linear_run:
@row:
        ld a,(hl)
        and d
        xor e
        ld (hl),a
        djnz @next
        ret
@next:
        ld a,l
        add a,40
        ld l,a
        jr nc,@row
        inc h
        jr @row
ENDIF
