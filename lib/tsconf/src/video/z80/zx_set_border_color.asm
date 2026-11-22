        MODULE zx_set_border_color
EXTERN _ts_video_set_border
SECTION code_clib
PUBLIC _zx_set_border_color

; Set an index in the default ZX palette bank F and write the border.
; Fastcall L = index. Clobbers AF, BC and L.
_zx_set_border_color:
        ld a,l
        or 0f0h
        ld l,a
        jp _ts_video_set_border
