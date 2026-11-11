        MODULE bc__graphics_circle_select
SECTION code_graphics
PUBLIC bc__graphics_circle_select
PUBLIC bc__graphics_circle_select_regs
EXTERN _bc_graphics_width
EXTERN _bc_graphics_height
EXTERN bc__graphics_select_writer

; Choose a native circle writer. Skip per-pixel clipping only when the whole
; bounding box fits inside the graphics surface.
;
; inside = cx >= r && cy >= r && cx + r < width && cy + r < height;
; select_writer(op, inside);
;
; A=operation. The frame entry reads cx +4, cy +6, radius +8 from IX.
; The register entry takes HL=cx, DE=cy, BC=radius. The caller holds a lease
; and has rejected negative radii. Return HL=writer, Z if none, and publish
; the same pointer for the midpoint loop. Preserve IX/IY, clobber AF/BC/DE.
bc__graphics_circle_select:
        ld l,(ix+4)
        ld h,(ix+5)
        ld e,(ix+6)
        ld d,(ix+7)
        ld c,(ix+8)
        ld b,(ix+9)
bc__graphics_circle_select_regs:
        push af
        bit 7,h
        jr nz,@outside
        bit 7,d
        jr nz,@outside

        ; Nonnegative signed words sum to at most 65534, so unsigned
        ; comparisons of center + radius cannot wrap at the screen edge.
        or a
        sbc hl,bc
        jr c,@outside
        add hl,bc
        add hl,bc
        push de
        ld de,(_bc_graphics_width)
        or a
        sbc hl,de
        pop hl
        jr nc,@outside
        or a
        sbc hl,bc
        jr c,@outside
        add hl,bc
        add hl,bc
        ld de,(_bc_graphics_height)
        or a
        sbc hl,de
        ld a,0
        adc a,0
        jr @select
@outside:
        xor a
@select:
        pop bc
        jp bc__graphics_select_writer
