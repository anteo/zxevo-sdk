        MODULE bc__draw_pentagon_xor_clipped
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
EXTERN _bc__draw_clip_point
EXTERN _bc__draw_pentagon_xor
SECTION code_graphics
PUBLIC _bc__draw_pentagon_xor_clipped
; XORs the point with the current ink color if it lies inside the Pentagon
; surface.
;
; Model:
;
; if (clip_point(x,y)) xor_pixel(x,y);
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
; clip_point returns CF=inside, the opposite of the axis clipper's CF=empty.
_bc__draw_pentagon_xor_clipped:
        call _bc__draw_clip_point
        ret nc
        jp _bc__draw_pentagon_xor
ENDIF
