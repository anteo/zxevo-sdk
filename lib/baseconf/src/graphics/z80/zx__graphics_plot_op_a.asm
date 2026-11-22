        MODULE zx__graphics_plot_op_a
INCLUDE "abi.inc"
EXTERN _bc__graphics_begin
EXTERN bc__graphics_plot_point
SECTION code_graphics
PUBLIC zx__graphics_plot_op_a

; Plot a single point under a graphics lease.
;
; if (!graphics_begin()) return;
; if (inside(x,y)) {
;     writer = draw_select(op, 1);
;     if (writer) writer(x,y);
; }
; video_end();
;
; SDCC x/y at SP+2/+4 and operation at SP+6. Shorthands and the classic
; Small-C entry pass operation in A. Preserve IX/IY, clobber AF/BC/DE/HL.
; Save the operation across begin and clipping, then save coordinates
; across writer selection.
zx__graphics_plot_op_a:
        push af
        call _bc__graphics_begin
        pop bc
        ret z
        ld a,b
        BC_ABI_LOAD_SDCC_PAIR 2
        jp bc__graphics_plot_point
