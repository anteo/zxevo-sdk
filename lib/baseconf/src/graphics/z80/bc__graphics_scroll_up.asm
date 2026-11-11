        MODULE bc__graphics_scroll_up
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC bc__graphics_scroll_up
EXTERN _bc__graphics_begin
EXTERN _bc__video_scroll_up_pixels
EXTERN _bc__video_end

; Run the upward scroll under a graphics lease. A=rows. The single
; argument byte is placed on the stack before begin. Preserve IX/IY.
bc__graphics_scroll_up:
        BC_ABI_PUSH_BYTE
        call _bc__graphics_begin
        jr z,@done
        call _bc__video_scroll_up_pixels
        inc sp
        jp _bc__video_end
@done:
        inc sp
        ret
