        MODULE bc__video_line_shift_x
SECTION code_clib
PUBLIC bc__video_line_shift_x

; DE = nonnegative x, B = shift (3 or 4). Return DE = x >> shift.
; Preserve HL/C/IX/IY, clobber AF/B.
;
; Converts a pixel column to a byte or group index for the layout chosen by
; the caller.
;
; Model:
;
; return x >> shift;
;
; Native unsigned DE shift with positive B=3/4. Passing zero would run 256
; iterations; callers must provide the documented count.
bc__video_line_shift_x:
        srl d
        rr e
        djnz bc__video_line_shift_x
        ret
