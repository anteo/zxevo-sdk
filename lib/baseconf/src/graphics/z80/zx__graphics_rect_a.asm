        MODULE zx__graphics_rect_a
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC zx__graphics_rect_a
EXTERN bc__graphics_rect_extent_a

; Forward SDCC x/y/width/height to the BaseConf Small-C scanline engine.
; A=SET or CLEAR. The original stack and IX/IY are preserved.
zx__graphics_rect_a:
        BC_ABI_PUSH_WORDS_FORWARD 4,2
        call bc__graphics_rect_extent_a
        BC_ABI_DROP_WORDS 4
        ret
