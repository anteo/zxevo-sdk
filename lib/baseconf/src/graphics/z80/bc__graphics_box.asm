        MODULE bc__graphics_box
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC bc__graphics_box
EXTERN _bc__graphics_begin
EXTERN _bc__video_hline
EXTERN _bc__video_vline
EXTERN _bc__video_end
EXTERN bc__graphics_extent_end

defc BC_BOX_HEIGHT = 4
defc BC_BOX_WIDTH = 6
defc BC_BOX_Y = 8
defc BC_BOX_X = 10
defc BC_BOX_OPERATION = -1
defc BC_BOX_RIGHT = -4
defc BC_BOX_BOTTOM = -6

; Paint the outline of a rectangle once per pixel under one graphics lease.
;
; if (!graphics_begin()) return;
; if (width > 0 && height > 0) {
;     right = extent_end(x,width); bottom = extent_end(y,height);
;     video_hline(x,right,y,op);
;     if (y < bottom) video_hline(x,right,bottom,op);
;     if (y+1 < bottom) {
;         video_vline(x,y+1,bottom-1,op);
;         if (x < right) video_vline(right,y+1,bottom-1,op);
;     }
; }
; video_end();
;
; Small-C caller-clean x,y,width,height, with height nearest the return
; address. A=operation. IX points at saved IX. Private words hold AF,
; right and bottom. Each axis engine receives its own writable SDCC
; arguments. Preserve IX/IY, clobber AF/BC/DE/HL. No BSS.
bc__graphics_box:
        push ix
        ld ix,0
        add ix,sp
        push af
        call _bc__graphics_begin
        jp z,@return
        ld a,(ix+BC_BOX_WIDTH+1)
        or (ix+BC_BOX_HEIGHT+1)
        jp m,@end

        ld e,(ix+BC_BOX_WIDTH)
        ld d,(ix+BC_BOX_WIDTH+1)
        ld a,d
        or e
        jr z,@end
        BC_ABI_LOAD_IX_WORD BC_BOX_X
        call bc__graphics_extent_end
        push hl

        ld e,(ix+BC_BOX_HEIGHT)
        ld d,(ix+BC_BOX_HEIGHT+1)
        ld a,d
        or e
        jr z,@end
        BC_ABI_LOAD_IX_WORD BC_BOX_Y
        call bc__graphics_extent_end
        push hl

        BC_ABI_LOAD_IX_WORD BC_BOX_Y
        call bc_box_hline
        BC_ABI_LOAD_IX_WORD BC_BOX_BOTTOM
        ld e,(ix+BC_BOX_Y)
        ld d,(ix+BC_BOX_Y+1)
        or a
        sbc hl,de
        jr z,@end                    ; a single row owns the entire outline
        add hl,de
        call bc_box_hline

        ; The two horizontal spans already own the corner pixels.
        BC_ABI_LOAD_IX_WORD BC_BOX_BOTTOM
        dec hl
        ld e,(ix+BC_BOX_Y)
        ld d,(ix+BC_BOX_Y+1)
        or a
        sbc hl,de
        jr z,@end                    ; two rows leave no interior span

        BC_ABI_LOAD_IX_WORD BC_BOX_X
        call bc_box_vline
        BC_ABI_LOAD_IX_WORD BC_BOX_RIGHT
        ld a,l
        cp (ix+BC_BOX_X)
        jr nz,@right
        ld a,h
        cp (ix+BC_BOX_X+1)
        jr z,@end                    ; a single column has only one side
@right:
        call bc_box_vline
@end:
        ld sp,ix
        pop ix
        jp _bc__video_end
@return:
        ld sp,ix
        pop ix
        ret

; Draw the top or bottom at HL=y. Preserve IX/IY.
bc_box_hline:
        ld a,(ix+BC_BOX_OPERATION)
        BC_ABI_PUSH_BYTE
        push hl
        BC_ABI_PUSH_IX_WORD BC_BOX_RIGHT
        BC_ABI_PUSH_IX_WORD BC_BOX_X
        call _bc__video_hline
        jr bc_box_drop_args

; Draw an interior side at HL=x. bottom-y is at least two. Preserve IX/IY.
bc_box_vline:
        ld a,(ix+BC_BOX_OPERATION)
        BC_ABI_PUSH_BYTE
        ex de,hl
        BC_ABI_LOAD_IX_WORD BC_BOX_BOTTOM
        dec hl
        push hl
        BC_ABI_LOAD_IX_WORD BC_BOX_Y
        inc hl
        push hl
        push de
        call _bc__video_vline
bc_box_drop_args:
        BC_ABI_DROP_WORDS 3
        inc sp
        ret
