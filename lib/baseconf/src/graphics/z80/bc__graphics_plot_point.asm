        MODULE bc__graphics_plot_point
EXTERN _bc__draw_clip_point
EXTERN _bc__video_end
EXTERN bc__draw_select_regs
SECTION code_graphics
PUBLIC bc__graphics_plot_point

bc__graphics_plot_point:
        ; Return through video_end after clipping, a missing writer, or a write.
        ld bc,_bc__video_end
        push bc
        push af
        call _bc__draw_clip_point
        pop bc
        ret nc
        push hl
        push de
        ld a,1
        call bc__draw_select_regs
        ld b,h
        ld c,l
        pop de
        pop hl
        ret z
        push bc
        ret
