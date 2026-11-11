        MODULE bc__video_hline_masks
SECTION code_clib
PUBLIC bc__video_hline_masks
EXTERN zx__span_masks

; IX: x0 +4, x1 +8. Return B = first bit mask, C = last bit mask.
;
; Returns the masks that limit painting to the selected pixels in the first
; and last bitmap bytes.
;
; Model:
;
; first=0xff>>(x0&7); last=(uint8_t)~(0xff>>((x1&7)+1));
;
; Inclusive endpoint masks use a nine-entry edge table, including edge[8]=0.
; AF/DE/HL volatile; IX/IY preserved. In a single byte, AND both masks together.
bc__video_hline_masks:
        ld a,(ix+4)
        ld c,(ix+8)
        jp zx__span_masks
