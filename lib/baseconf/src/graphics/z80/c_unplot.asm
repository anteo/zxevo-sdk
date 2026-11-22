        MODULE c_unplot
EXTERN _unplot
SECTION code_graphics
PUBLIC _c_unplot

; Small-C caller-clean x,y. Tail-enter the pixel wrapper with op in A.
defc _c_unplot = _unplot
