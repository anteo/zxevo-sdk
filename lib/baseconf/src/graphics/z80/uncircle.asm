        MODULE uncircle
SECTION code_graphics
PUBLIC _uncircle
EXTERN bc__circle_draw

; Small-C caller-clean. Clear pixels through the common circle entry.
_uncircle:
        ld a,1
        jp bc__circle_draw
