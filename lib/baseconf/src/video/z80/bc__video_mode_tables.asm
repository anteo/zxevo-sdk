        MODULE bc__video_mode_tables
SECTION rodata_clib
PUBLIC bc__video_mode_by_xx77
PUBLIC _bc__video_first_screen_pages

; xx77 modes 0/2/6/7 are ATM320/ATM640/ATM text/EVO text respectively.
bc__video_mode_by_xx77:
        defb 3,0FFh,4,0FFh,0FFh,0FFh,5,6

; ZX, Multicolor, Pentagon, ATM320, ATM640, ATM text and Evo text.
; Screen 1 adds two to each of these first physical pages.
_bc__video_first_screen_pages:
        defb 5,5,4,1,1,1,8
