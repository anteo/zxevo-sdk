        MODULE bc__draw_clip_point
SECTION code_graphics
PUBLIC _bc__draw_clip_point
EXTERN _bc_graphics_width
EXTERN _bc_graphics_height

; Input HL=x, DE=y. Carry means both coordinates are inside the active mode.
;
; Tests whether a point lies inside the active graphics surface and reports
; the result in carry.
;
; Model:
;
; inside=((uint16_t)x<width && (uint16_t)y<height); return CF=inside.
;
; Unsigned comparisons reject negative coordinates (8000h through FFFFh).
; AF/BC volatile; HL/DE/IX/IY preserved. Dimensions come from an active lease;
; no pixel access or page change occurs.
_bc__draw_clip_point:
        push hl
        push de
        ld bc,(_bc_graphics_width)
        or a
        sbc hl,bc
        jr nc,_bc_draw_clip_out
        ex de,hl
        ld bc,(_bc_graphics_height)
        or a
        sbc hl,bc
        jr nc,_bc_draw_clip_out
        pop de
        pop hl
        scf
        ret
_bc_draw_clip_out:
        pop de
        pop hl
        or a
        ret
