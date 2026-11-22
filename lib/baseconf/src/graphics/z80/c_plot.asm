        MODULE c_plot
EXTERN _plot
SECTION code_graphics
PUBLIC _c_plot

; Small-C caller-clean x,y. Tail-enter the pixel wrapper with op in A.
defc _c_plot = _plot
