        MODULE zx__ellipse_endpoints
SECTION code_graphics
PUBLIC zx__ellipse_endpoints

; HL=center, DE=radius -> HL=center-radius, DE=center+radius. Preserve BC.
zx__ellipse_endpoints:
        or a
        sbc hl,de
        push hl
        add hl,de
        add hl,de
        ex de,hl
        pop hl
        ret
