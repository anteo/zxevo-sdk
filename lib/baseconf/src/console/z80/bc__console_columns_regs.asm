        MODULE bc__console_columns_regs
SECTION code_clib
PUBLIC bc__console_columns_regs
EXTERN _bc__video_width
EXTERN zx__font_columns

; E = advance -> HL = video width / advance. Zero advance returns zero.
; Preserve IX/IY. No C ABI adapter or CRT division dependency.
;
; Returns the current video width expressed in whole cells of the supplied
; font advance.
;
; Model:
;
; return columns_for_width(video_width(), advance);
;
; Save DE across the C getter; AF/BC/DE/HL volatile, IX/IY preserved.
bc__console_columns_regs:
        push de
        call _bc__video_width
        pop de
        jp zx__font_columns
