IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_OFFSET
        MODULE bc__video_line_zx_row
SECTION code_clib
PUBLIC bc__video_line_zx_row
EXTERN zx__bitmap_offset

; Shared axis frame: x +4, y +6, last coordinate +8, operation +10.
; Return HL = ZX row offset, with no x/plane/page contribution.
;
; Returns the ZX bitmap row offset for the first scanline of an axis-aligned
; span.
;
; Model:
;
; return zx__offset((uint8_t)y,0);
;
; Y is clipped to 0..191. Tail adapter to the register formula; AF/C/DE/HL
; volatile, IX/IY preserved; it intentionally includes no x/page/plane bits.
bc__video_line_zx_row:
        ld c,(ix+6)
        ld de,0
        jp zx__bitmap_offset
ENDIF
