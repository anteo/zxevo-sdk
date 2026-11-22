        MODULE zx__graphics_hline_op_a
INCLUDE "abi.inc"
EXTERN _bc__graphics_begin
EXTERN _bc__video_end
EXTERN _bc__video_hline
SECTION code_graphics
PUBLIC zx__graphics_hline_op_a

; Draw an axis span under a graphics lease.
;
; if (op <= XOR && graphics_begin()) { draw_axis_span(args, op); video_end(); }
;
; SDCC three words plus operation:8. Shorthands pass the operation in A.
; The video kernel may rewrite its private copy of the coordinates.
; Preserve IX/IY, clobber AF/BC/DE/HL.
zx__graphics_hline_op_a:
        push af
        call _bc__graphics_begin
        pop bc
        ret z
        push bc
        inc sp
        BC_ABI_PUSH_WORDS_REVERSE 3,3
        call _bc__video_hline
        BC_ABI_DROP_WORDS 3
        inc sp
        jp _bc__video_end
