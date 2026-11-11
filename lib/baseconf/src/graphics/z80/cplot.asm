        MODULE cplot
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _cplot
EXTERN _bc__graphics_begin
EXTERN bc__graphics_pixel_regs
EXTERN _bc__video_end

; Write the requested color at an in-bounds point under a graphics lease.
;
; if (!graphics_begin()) return;
; if (inside(x,y)) video_pixel(x,y,SET_COLOR,(uint8_t)color);
; video_end();
;
; Small-C caller-clean color +2, y +4, x +6. Preserve IX/IY.
_cplot:
        call _bc__graphics_begin
        ret z
        BC_ABI_LOAD_SDCC_PAIR 4
        ex de,hl
        push hl
        ld hl,4
        add hl,sp
        ld b,(hl)                    ; low byte of the original color word
        ld c,4                       ; PIXEL_SET_COLOR
        pop hl
        call bc__graphics_pixel_regs
        jp _bc__video_end
