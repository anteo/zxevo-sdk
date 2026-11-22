        MODULE zx_graphics_end
EXTERN _bc__video_end
SECTION code_clib
PUBLIC _zx_graphics_end

; Shared no-argument SDCC entry for ending a graphics operation.
defc _zx_graphics_end = _bc__video_end
