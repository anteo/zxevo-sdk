        MODULE circle
SECTION code_graphics
PUBLIC _circle
EXTERN bc__circle_draw

; Small-C caller-clean. Set pixels through the common circle entry.
_circle:
        xor a
        jp bc__circle_draw
