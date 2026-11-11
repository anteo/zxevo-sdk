        MODULE graphics_clear
SECTION code_graphics
PUBLIC _clg
PUBLIC _cclg
EXTERN _bc__video_clear

; Both no-argument z88dk entries discard the video clear status.
defc _clg = _bc__video_clear
defc _cclg = _bc__video_clear
