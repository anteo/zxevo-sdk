        MODULE bc__draw_pentagon_set_clipped
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
EXTERN _bc__draw_clip_point
EXTERN _bc__draw_pentagon_set
SECTION code_graphics
PUBLIC _bc__draw_pentagon_set_clipped

; Pentagon and ATM 320 use the same packed 4-bit pixel byte format. The mode
; determines only the byte offset; x bits select the already mapped page.
; Paints the point with the current ink color if it lies inside the Pentagon
; surface.
;
; Model:
;
; if (clip_point(x,y)) set_pixel(x,y);
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
; clip_point returns CF=inside, the opposite of the axis clipper's CF=empty.
_bc__draw_pentagon_set_clipped:
        call _bc__draw_clip_point
        ret nc
        jp _bc__draw_pentagon_set
ENDIF
