        MODULE xordraw
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _xordraw
EXTERN _bc__graphics_draw_line

; Small-C caller-clean. Reorder the input words for the SDCC drawing
; entry and append the fixed operation byte. Preserve IX/IY.
_xordraw:
        ld a,2
        BC_ABI_PUSH_BYTE
        BC_ABI_PUSH_WORDS_FORWARD 4,3
        call _bc__graphics_draw_line
        BC_ABI_DROP_WORDS 4
        inc sp
        ret
