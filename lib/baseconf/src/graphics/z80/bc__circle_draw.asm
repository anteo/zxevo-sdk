        MODULE bc__circle_draw
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC bc__circle_draw
EXTERN _bc__graphics_begin
EXTERN bc__graphics_circle_select_regs
EXTERN _bc__video_end
EXTERN w_draw_circle

defc BC_CIRCLE_RADIUS = 6
defc BC_CIRCLE_Y = 8
defc BC_CIRCLE_X = 10

; Draw a wide z88dk circle with step one. A zero radius paints the center once.
;
; if (radius < 0 || !graphics_begin()) return;
; writer = select_circle_writer(op, cx, cy, radius);
; if (writer) {
;     if (radius == 0) writer(cx, cy);
;     else wide_circle(cx, cy, radius, writer);
; }
; video_end();
;
; Small-C caller-clean x,y,radius,skip, operation in A. IX points to saved IX,
; with skip at IX+4 for the public ABI. The wide kernel always steps by one.
; Save the coordinate registers across writer selection and then use IX for
; the selected writer. Preserve caller IX/IY, clobber AF/BC/DE/HL.
bc__circle_draw:
        push ix
        ld ix,0
        add ix,sp
        bit 7,(ix+BC_CIRCLE_RADIUS+1)
        jr nz,@return
        push af
        call _bc__graphics_begin
        pop bc
        jr z,@return
        ld a,b
        BC_ABI_LOAD_IX_WORD BC_CIRCLE_X
        ld e,(ix+BC_CIRCLE_Y)
        ld d,(ix+BC_CIRCLE_Y+1)
        ld c,(ix+BC_CIRCLE_RADIUS)
        ld b,(ix+BC_CIRCLE_RADIUS+1)
        push hl
        push de
        push bc
        call bc__graphics_circle_select_regs
        push hl
        pop ix
        pop bc
        pop de
        pop hl
        jr z,@end
        call @run
@end:
        pop ix
        jp _bc__video_end
@return:
        pop ix
        ret

; Both targets return to the lease cleanup. The writer takes HL=x, DE=y.
@run:
        ld a,b
        or c
        jr z,@plot_center
        ex de,hl
        jp w_draw_circle
@plot_center:
        jp (ix)
