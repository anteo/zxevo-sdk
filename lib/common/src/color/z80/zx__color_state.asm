        MODULE zx__color_state
SECTION data_clib
PUBLIC zx__ink
PUBLIC zx__paper

; Keep ink and paper adjacent for consumers loading the pair into DE.
zx__ink:   defb 0
zx__paper: defb 7
