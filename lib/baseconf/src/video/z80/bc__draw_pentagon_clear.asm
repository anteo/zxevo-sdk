        MODULE bc__draw_pentagon_clear
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
EXTERN bc__draw_packed_store
EXTERN bc__draw_pentagon_address
EXTERN zx__paper
SECTION code_graphics
PUBLIC _bc__draw_pentagon_clear
; Replaces one Pentagon packed pixel with the current paper color while
; retaining its neighbor.
;
; Model:
;
; replace_selected_field(paper);
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
_bc__draw_pentagon_clear:
        call bc__draw_pentagon_address
        ld a,(zx__paper)
        and 0fh
        jp bc__draw_packed_store
ENDIF
