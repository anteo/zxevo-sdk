        MODULE zx__graphics_circle_op_a
INCLUDE "abi.inc"
EXTERN _bc__circle_loop
EXTERN _bc__graphics_begin
EXTERN _bc__video_end
EXTERN bc__graphics_circle_select
SECTION code_graphics
PUBLIC zx__graphics_circle_op_a

; Draw a midpoint circle under a graphics lease.
;
; if (radius < 0 || !graphics_begin()) return;
; if (select_circle_writer(op, cx, cy, radius)) circle_loop(cx,cy,radius);
; video_end();
;
; SDCC three words followed by a byte. Shorthands take op in A. IX frames
; the original arguments during selection. Preserve IX/IY.
zx__graphics_circle_op_a:
        push af
        ld hl,9                      ; radius high byte with saved AF
        add hl,sp
        bit 7,(hl)
        jr nz,@reject
        call _bc__graphics_begin
        pop bc
        ret z
        push ix
        ld ix,0
        add ix,sp
        ld a,b
        call bc__graphics_circle_select
        jr z,@end
        BC_ABI_PUSH_WORDS_REVERSE 3,4
        call _bc__circle_loop
        BC_ABI_DROP_WORDS 3
@end:
        pop ix
        jp _bc__video_end
@reject:
        pop af
        ret
