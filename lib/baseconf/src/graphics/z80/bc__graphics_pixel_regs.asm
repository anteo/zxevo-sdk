        MODULE bc__graphics_pixel_regs
SECTION code_graphics
PUBLIC bc__graphics_pixel_regs
EXTERN _bc__draw_clip_point
EXTERN bc__video_pixel_regs

; Clip a pixel read, test or color write under an existing graphics lease.
;
; return inside(x,y) ? video_pixel(x,y,operation,color) : 0;
;
; HL=x, DE=y, C=operation, B=color. Return byte in L. Preserve IX/IY,
; clobber AF/BC/DE/HL. COLOR has no result.
bc__graphics_pixel_regs:
        push bc
        call _bc__draw_clip_point
        pop bc
        jp c,bc__video_pixel_regs
        ld l,0
        ret
