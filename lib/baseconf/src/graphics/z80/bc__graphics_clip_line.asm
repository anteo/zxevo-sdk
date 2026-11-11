        MODULE bc__graphics_clip_line
SECTION code_graphics
PUBLIC bc__graphics_clip_line
EXTERN _bc_graphics_width
EXTERN _bc_graphics_height
EXTERN bc__graphics_select_writer
EXTERN zx__line_clip

; Select the clipped writer for the current lease and pass its bounds.
; Operation in A, SDCC endpoints on the stack. Preserve IX/IY.
bc__graphics_clip_line:
        ld b,a
        xor a
        call bc__graphics_select_writer
        ret z
        ld bc,(_bc_graphics_width)
        ld de,(_bc_graphics_height)
        jp zx__line_clip
