        MODULE xorcircle
SECTION code_graphics
PUBLIC _xorcircle
EXTERN bc__circle_draw

; Small-C caller-clean. Toggle pixels through the common circle entry.
_xorcircle:
        ld a,2
        jp bc__circle_draw
