        MODULE xorborder
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _xorborder
EXTERN _bc__graphics_begin
EXTERN _bc_graphics_width
EXTERN _bc_graphics_height
EXTERN _bc__video_end
EXTERN bc__draw_select_regs
EXTERN bc__graphics_extent_end
EXTERN zx__clip_axis

defc BC_BORDER_HEIGHT = 4
defc BC_BORDER_WIDTH = 6
defc BC_BORDER_Y = 8
defc BC_BORDER_X = 10
defc BC_BORDER_WRITER = -2
defc BC_BORDER_RIGHT = -4
defc BC_BORDER_BOTTOM = -6
defc BC_BORDER_VERTICAL = -9
defc BC_BORDER_FIRST = -12
defc BC_BORDER_LAST = -14

; Toggle the dotted sides of a rectangle. Corners are excluded. A single
; row or column has coincident sides whose XORs cancel.
;
; if (width < 2 || height < 2 || !graphics_begin()) return;
; writer = draw_select(XOR, 1);
; if (writer) {
;     draw_dotted_pair(y, bottom, height_of_screen, x, right, vertical);
;     draw_dotted_pair(x, right, width_of_screen, y, bottom, horizontal);
; }
; video_end();
;
; Small-C caller-clean x,y,width,height. IX points at saved IX. The frame
; holds the unchecked writer and saturated right/bottom words. Preserve
; IX/IY, clobber AF/BC/DE/HL. No BSS.
_xorborder:
        push ix
        ld ix,0
        add ix,sp
        ld a,(ix+BC_BORDER_WIDTH+1)
        or (ix+BC_BORDER_HEIGHT+1)
        jp m,@return
        ld a,(ix+BC_BORDER_WIDTH)
        and 0FEh
        or (ix+BC_BORDER_WIDTH+1)
        jr z,@return
        ld a,(ix+BC_BORDER_HEIGHT)
        and 0FEh
        or (ix+BC_BORDER_HEIGHT+1)
        jr z,@return
        call _bc__graphics_begin
        jr z,@return

        ld a,1                       ; select the unchecked XOR writer once
        ld b,2
        call bc__draw_select_regs
        jr z,@end
        push hl

        BC_ABI_LOAD_IX_WORD BC_BORDER_X
        ld e,(ix+BC_BORDER_WIDTH)
        ld d,(ix+BC_BORDER_WIDTH+1)
        call bc__graphics_extent_end
        push hl
        BC_ABI_LOAD_IX_WORD BC_BORDER_Y
        ld e,(ix+BC_BORDER_HEIGHT)
        ld d,(ix+BC_BORDER_HEIGHT+1)
        call bc__graphics_extent_end
        push hl

        ex de,hl                     ; DE = bottom
        BC_ABI_LOAD_IX_WORD BC_BORDER_Y
        ld bc,(_bc_graphics_height)
        ld a,1
        call bc_border_pair

        BC_ABI_LOAD_IX_WORD BC_BORDER_X
        ld e,(ix+BC_BORDER_RIGHT)
        ld d,(ix+BC_BORDER_RIGHT+1)
        ld bc,(_bc_graphics_width)
        xor a
        call bc_border_pair
@end:
        ld sp,ix
        pop ix
        jp _bc__video_end
@return:
        pop ix
        ret

; Clip the varying coordinate and align it to the original dotted phase.
;
; (first,last) = clip_span(origin,end-1,limit);
; if (empty) return;
; if ((first & 1) == (origin & 1)) ++first;
; draw_side(first,last,fixed0); draw_side(first,last,fixed1);
;
; HL=origin, DE=end, BC=axis limit, A=vertical flag. Caller has a lease.
; Below the pair return address at IX-8 are the direction, first and last
; words. The origin parity is temporary and is discarded after clipping.
bc_border_pair:
        push af
        ld a,l
        push af
        dec de                       ; exclude the far corner
        call zx__clip_axis
        jr c,bc_border_empty
        pop af
        xor l
        rrca
        jr c,bc_border_span          ; odd offset from the original origin
        inc hl                       ; excludes the near corner too
bc_border_span:
        push hl
        push de
        ld a,(ix+BC_BORDER_VERTICAL)
        or a
        jr z,bc_border_horizontal
        BC_ABI_LOAD_IX_WORD BC_BORDER_X
        ld de,(_bc_graphics_width)
        call bc_border_side
        BC_ABI_LOAD_IX_WORD BC_BORDER_RIGHT
        ld de,(_bc_graphics_width)
        jr bc_border_second_side
bc_border_horizontal:
        BC_ABI_LOAD_IX_WORD BC_BORDER_Y
        ld de,(_bc_graphics_height)
        call bc_border_side
        BC_ABI_LOAD_IX_WORD BC_BORDER_BOTTOM
        ld de,(_bc_graphics_height)
bc_border_second_side:
        call bc_border_side
        pop bc
        pop bc
        pop af
        ret
bc_border_empty:
        pop af
        pop af
        ret

; Reject an off-screen side once, then toggle every other visible pixel.
;
; if ((uint16_t)fixed >= limit) return;
; for (p = first; p <= last; p += 2) writer(vertical ? fixed : p,
;                                         vertical ? p : fixed);
;
; HL=fixed coordinate, DE=perpendicular limit. Save varying coordinate,
; limit and fixed coordinate across each writer call. IX is the frame.
bc_border_side:
        or a
        sbc hl,de
        ret nc
        add hl,de
        ld b,h
        ld c,l
        BC_ABI_LOAD_IX_WORD BC_BORDER_FIRST
        ld e,(ix+BC_BORDER_LAST)
        ld d,(ix+BC_BORDER_LAST+1)
bc_border_next:
        ld a,e
        sub l
        ld a,d
        sbc a,h
        ret c
        push bc
        push de
        push hl
        ld d,b
        ld e,c
        ld a,(ix+BC_BORDER_VERTICAL)
        or a
        jr z,bc_border_plot
        ex de,hl
bc_border_plot:
        call bc_border_writer
        pop hl
        pop de
        pop bc
        inc hl
        inc hl
        jr bc_border_next

; Tail-enter the selected native writer with HL=x and DE=y.
bc_border_writer:
        ld c,(ix+BC_BORDER_WRITER)
        ld b,(ix+BC_BORDER_WRITER+1)
        push bc
        ret
