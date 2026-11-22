        MODULE clg
EXTERN _bc__video_clear
SECTION code_graphics
PUBLIC _clg

; Both no-argument z88dk entries discard the video clear status.
defc _clg = _bc__video_clear
