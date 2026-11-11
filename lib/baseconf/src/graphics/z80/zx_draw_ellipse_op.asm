        MODULE zx_draw_ellipse_op
INCLUDE "abi.inc"
INCLUDE "graphics/z80/zx__ellipse.inc"
SECTION code_graphics
PUBLIC _zx_draw_ellipse_op
PUBLIC zx__graphics_ellipse_op_a
EXTERN _bc__graphics_begin
EXTERN _bc__draw_clip_point
EXTERN bc__graphics_select_writer
EXTERN _bc__line_loop
EXTERN _bc_draw_callback
EXTERN _bc__video_end
EXTERN zx__ellipse_walk
EXTERN zx__ellipse_endpoints

; Draw an axis-aligned midpoint ellipse using the scaled rectangle form.
;
; if (rx < 0 || ry < 0 || !graphics_begin()) return;
; x0 = cx-rx; x1 = cx+rx; y0 = cy-ry; y1 = cy+ry;
; if (select_writer(op, bounding_box_inside)) {
;     if (rx == 0 || ry == 0) line_loop(x0,y0,x1,y1);
;     else zx__ellipse_walk(frame, writer);
; }
; video_end();
;
; SDCC cx +2, cy +4, rx +6, ry +8, operation:8 at +10. The shorthand entry
; takes operation in A. Preserve IX/IY, clobber AF/BC/DE/HL and shadow
; BC/DE/HL. After begin, IX points to 34 bytes of private stack state.
; Saved IY, saved IX and the return address sit above it. IY holds the
; pixel writer during the ellipse walk. Only the degenerate line path
; passes coordinate copies below the frame. Error terms are signed
; 32-bit values with the common factor of 16 omitted.
_zx_draw_ellipse_op:
        ld hl,10
        add hl,sp
        ld a,(hl)
zx__graphics_ellipse_op_a:
        push ix
        ld ix,0
        add ix,sp
        bit 7,(ix+9)
        jr nz,bc_ellipse_reject
        bit 7,(ix+11)
        jr nz,bc_ellipse_reject
        push af
        call _bc__graphics_begin
        pop bc                       ; B = operation
        jr nz,bc_ellipse_open
bc_ellipse_reject:
        pop ix
        ret

bc_ellipse_open:
        push iy
        ld hl,-ZX_ELLIPSE_FRAME
        add hl,sp
        ld sp,hl
        push hl
        pop ix

        BC_ABI_LOAD_IX_WORD ZX_ELLIPSE_CX
        ZX_ELLIPSE_LOAD_DE ZX_ELLIPSE_RX
        call zx__ellipse_endpoints
        ZX_ELLIPSE_STORE_HL ZX_ELLIPSE_X0
        ZX_ELLIPSE_STORE_DE ZX_ELLIPSE_X1
        BC_ABI_LOAD_IX_WORD ZX_ELLIPSE_CY
        ZX_ELLIPSE_LOAD_DE ZX_ELLIPSE_RY
        call zx__ellipse_endpoints
        ZX_ELLIPSE_STORE_HL ZX_ELLIPSE_Y0
        ZX_ELLIPSE_STORE_DE ZX_ELLIPSE_Y1

        ; For a nonnegative center, center-radius fits a signed word and
        ; center+radius fits an unsigned word. Only the upper corner then
        ; needs the common point check.
        ld a,(ix+ZX_ELLIPSE_CX+1)
        or (ix+ZX_ELLIPSE_CY+1)
        or (ix+ZX_ELLIPSE_X0+1)
        or (ix+ZX_ELLIPSE_Y0+1)
        jp m,bc_ellipse_clipped
        BC_ABI_LOAD_IX_WORD ZX_ELLIPSE_X1
        push bc
        call _bc__draw_clip_point    ; DE still holds the upper Y bound
        pop bc
        ld a,0
        adc a,0
        jr bc_ellipse_select
bc_ellipse_clipped:
        xor a
bc_ellipse_select:
        call bc__graphics_select_writer
        jp z,bc_ellipse_end
        BC_ABI_LOAD_IX_WORD ZX_ELLIPSE_RX
        ld a,h
        or l
        jp z,bc_ellipse_line
        ZX_ELLIPSE_LOAD_DE ZX_ELLIPSE_RY
        ld a,d
        or e
        jp z,bc_ellipse_line

        ld iy,(_bc_draw_callback)
        call zx__ellipse_walk
        jr bc_ellipse_end

bc_ellipse_line:
        BC_ABI_PUSH_IX_WORD ZX_ELLIPSE_Y1
        BC_ABI_PUSH_IX_WORD ZX_ELLIPSE_X1
        BC_ABI_PUSH_IX_WORD ZX_ELLIPSE_Y0
        BC_ABI_PUSH_IX_WORD ZX_ELLIPSE_X0
        call _bc__line_loop
        BC_ABI_DROP_WORDS 4
bc_ellipse_end:
        ld hl,ZX_ELLIPSE_FRAME
        add hl,sp
        ld sp,hl
        pop iy
        pop ix
        jp _bc__video_end
