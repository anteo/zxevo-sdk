        MODULE bc__graphics_scroll_horizontal
SECTION code_graphics
PUBLIC bc__graphics_scroll_horizontal
EXTERN _bc__graphics_begin
EXTERN _bc__video_scroll_horizontal
EXTERN _bc__video_end

; Run the horizontal scroll under a graphics lease. L=pixels, H=right.
; Save the two packed argument bytes across begin. Preserve IX/IY.
bc__graphics_scroll_horizontal:
        push hl
        call _bc__graphics_begin
        jr z,@done
        call _bc__video_scroll_horizontal
        pop bc
        jp _bc__video_end
@done:
        pop bc
        ret
