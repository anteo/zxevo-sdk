        MODULE bc__graphics_prepare_line
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC bc__graphics_prepare_line_a
EXTERN _bc__draw_clip_point
EXTERN bc__graphics_select_writer
EXTERN bc__graphics_clip_line
EXTERN _bc__line_loop

; Select the unchecked native loop for an entirely visible segment.
;
; if (op > XOR) return;
; if (!inside(start) || !inside(end)) { clip_line(endpoints, op); return; }
; if (select_writer(op, 1)) line_loop(start, end);
;
; Four signed endpoint words on the stack in SDCC order, operation in A.
; Caller owns a graphics lease. Preserve IX/IY, clobber AF/BC/DE/HL.
; Save the operation across both point tests. Both paths tail-enter with
; the original endpoint words.
bc__graphics_prepare_line_a:
        cp 3
        ret nc
        push af
        BC_ABI_LOAD_SDCC_PAIR 4
        call _bc__draw_clip_point
        jr nc,@clip
        BC_ABI_LOAD_SDCC_PAIR 8
        call _bc__draw_clip_point
        jr nc,@clip
        pop bc
        ld a,1
        call bc__graphics_select_writer
        ret z
        jp _bc__line_loop
@clip:
        pop af
        jp bc__graphics_clip_line
