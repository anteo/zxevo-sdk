        MODULE bc__video_line_return
SECTION code_clib
PUBLIC bc__video_line_return

; Every axis-line backend shares the caller's saved IX frame. No static scratch.
; Shared axis-line tail epilogue: discard all locals below the persistent IX
; frame, restore caller IX, return void. Requires the dispatcher saved-IX frame;
; this is not an independently callable C function. Other working registers
; remain volatile; IY was never changed by the axis backends.
bc__video_line_return:
        ld sp,ix
        pop ix
        ret
