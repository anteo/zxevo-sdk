        MODULE ts_video_set_border
SECTION code_clib
PUBLIC _zx_set_border_color
PUBLIC _ts_video_set_border

; Set an index in the default ZX palette bank F and write the border.
; Fastcall L = index. Clobbers AF, BC and L.
_zx_set_border_color:
        ld a,l
        or 0f0h
        ld l,a

; Set the border's CRAM index. Fastcall L = value. Clobbers BC only.
_ts_video_set_border:
        ld bc,0fafh
        out (c),l
        ret
