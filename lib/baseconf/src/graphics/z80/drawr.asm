        MODULE drawr
SECTION code_graphics
PUBLIC _drawr
EXTERN _move

; Alias with the same Small-C caller-clean dx,dy ABI.
defc _drawr = _move
