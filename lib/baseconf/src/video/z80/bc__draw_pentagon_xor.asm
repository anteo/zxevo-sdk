        MODULE bc__draw_pentagon_xor
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
EXTERN bc__draw_packed_xor
EXTERN bc__draw_pentagon_address
SECTION code_graphics
PUBLIC _bc__draw_pentagon_xor
; Applies the current ink color as an XOR to one Pentagon packed pixel while
; retaining its neighbor.
;
; Model:
;
; replace_selected_field(decode_selected_field() ^ ink);
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
_bc__draw_pentagon_xor:
        call bc__draw_pentagon_address
        jp bc__draw_packed_xor
ENDIF
