        MODULE bc__draw_atm640_set
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
EXTERN bc__draw_atm640_address
SECTION code_graphics
PUBLIC _bc__draw_atm640_set

; Sets one ATM640 bitmap pixel while retaining the other bits in its byte.
;
; Model:
;
; *bitmap |= mask;
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
_bc__draw_atm640_set:
        call bc__draw_atm640_address
        or (hl)
        ld (hl),a
        ret
ENDIF
