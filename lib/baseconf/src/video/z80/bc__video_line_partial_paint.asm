        MODULE bc__video_line_partial_paint
SECTION code_clib
PUBLIC bc__video_line_partial_paint

; A = selected physical bits, B = full-byte AND, C = full-byte XOR.
; Return D = AND preserving unselected bits, E = selected XOR bits.
; Preserve HL/BC/IX/IY. Shared by bitmap and packed axis lines.
;
; Restricts a byte paint operation to selected bits so neighboring pixels are
; preserved.
;
; Model:
;
; partial_AND=(uint8_t)~selected | full_AND; partial_XOR=full_XOR & selected;
;
; This reduces every edge update to (old&partial_AND)^partial_XOR while
; retaining all unselected bits. Register and preservation contract is above.
bc__video_line_partial_paint:
        ld e,a
        cpl
        or b
        ld d,a
        ld a,c
        and e
        ld e,a
        ret
