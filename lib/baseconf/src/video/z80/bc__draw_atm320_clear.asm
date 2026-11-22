        MODULE bc__draw_atm320_clear
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
EXTERN bc__draw_atm320_address
EXTERN bc__draw_packed_store
EXTERN zx__paper
SECTION code_graphics
PUBLIC _bc__draw_atm320_clear
; Replaces one ATM320 packed pixel with the current paper color while
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
_bc__draw_atm320_clear:
        call bc__draw_atm320_address
        ld a,(zx__paper)
        and 0fh
        jp bc__draw_packed_store
ENDIF
