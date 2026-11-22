; z88dk wide circle for square pixels, with a fixed unit step.
; Based on Stefano's 2019 version using IX for the pixel writer.

IF  !__CPU_INTEL__&&!__CPU_GBZ80__
SECTION code_graphics
PUBLIC  w_draw_circle
EXTERN  l_graphics_cmp

; Walk the octant and emit the eight symmetric points in the original order.
;
; r = radius; x = 0; error = r / 2;
; while (x < r) {
;     if (error < 0) { error += r; --r; }
;     error -= x + 1;
;     emit(x,r); emit(-x,r); emit(x,-r); emit(-x,-r);
;     emit(r,x); emit(-r,x); emit(r,-x); emit(-r,-x);
;     ++x;
; }
;
; DE=cx, HL=cy, BC=positive radius, IX=writer. Each emit adds the center
; and passes HL=x, DE=y to the writer under the caller's video lease.
; Preserve IX/IY, clobber AF/BC/DE/HL. State lives in BSS. Coincident points
; are emitted as listed, including for XOR.
w_draw_circle:
        ld      (x0l), de
        ld      (y0l), hl
        ld      (rlv), bc

        xor     a
        ld      (cxl), a
        ld      (cxh), a
        srl     b
        rr      c
        ld      (dal), bc
;Line 9905
l9905:
        ld      bc, (rlv)
        ld      de, (cxl)
        ld      h, b
        ld      l, c
        call    l_graphics_cmp
        ret     nc
;Line 9910
        ld      a, (dahi)
        bit     7, a
        jr      z, l9915

        ld      bc, (dal)
        ld      hl, (rlv)
        add     hl, bc
        ld      b, h
        ld      c, l
        ld      (dal), bc

        ld      hl, (rlv)
        dec     hl
        ld      (rlv), hl
;Line 9915
l9915:
        ld      bc, (dal)
        dec     bc
        ld      h, b
        ld      l, c
        ld      de, (cxl)
        or      a
        sbc     hl, de
        ld      b, h
        ld      c, l
        ld      (dal), bc

l9920:
        ld      bc, (y0l)
        ld      de, (rlv)
    ;srl d
    ;rr e
        ld      h, b
        ld      l, c
        add     hl, de
        push    hl

        ld      bc, (x0l)
        ld      de, (cxl)
        ld      h, b
        ld      l, c
        add     hl, de
        pop     de

        call    do_w_plot                   ; (cx,r)

        ld      bc, (y0l)
        ld      de, (rlv)
    ;srl d
    ;rr e
        ld      h, b
        ld      l, c
        add     hl, de
        push    hl

        ld      bc, (x0l)
        ld      de, (cxl)
        ld      h, b
        ld      l, c
        or      a
        sbc     hl, de
        pop     de

        call    do_w_plot                   ; (-cx,r)

        ld      bc, (y0l)
        ld      de, (rlv)
    ;srl d
    ;rr e
        ld      h, b
        ld      l, c
        or      a
        sbc     hl, de
        push    hl

        ld      bc, (x0l)
        ld      de, (cxl)
        ld      h, b
        ld      l, c
        add     hl, de
        pop     de

        call    do_w_plot                   ; (cx,-r)

        ld      bc, (y0l)
        ld      de, (rlv)
    ;srl d
    ;rr e
        ld      h, b
        ld      l, c
        or      a
        sbc     hl, de
        push    hl

        ld      bc, (x0l)
        ld      de, (cxl)
        ld      h, b
        ld      l, c
        or      a
        sbc     hl, de
        pop     de

        call    do_w_plot                   ; (-cx,-r)


        ld      bc, (y0l)
        ld      de, (cxl)
    ;srl d
    ;rr e
        ld      h, b
        ld      l, c
        add     hl, de
        push    hl

        ld      bc, (x0l)
        ld      de, (rlv)
        ld      h, b
        ld      l, c
        add     hl, de
        pop     de

        call    do_w_plot                   ; (r,cx)

        ld      bc, (y0l)
        ld      de, (cxl)
    ;srl d
    ;rr e
        ld      h, b
        ld      l, c
        add     hl, de
        push    hl

        ld      bc, (x0l)
        ld      de, (rlv)
        ld      h, b
        ld      l, c
        or      a
        sbc     hl, de
        pop     de

        call    do_w_plot                   ; (-r,cx)

        ld      bc, (y0l)
        ld      de, (cxl)
    ;srl d
    ;rr e
        ld      h, b
        ld      l, c
        or      a
        sbc     hl, de
        push    hl

        ld      bc, (x0l)
        ld      de, (rlv)
        ld      h, b
        ld      l, c
        add     hl, de
        pop     de

        call    do_w_plot                   ; (r,-cx)

        ld      bc, (y0l)
        ld      de, (cxl)
    ;srl d
    ;rr e
        ld      h, b
        ld      l, c
        or      a
        sbc     hl, de
        push    hl

        ld      bc, (x0l)
        ld      de, (rlv)
        ld      h, b
        ld      l, c
        or      a
        sbc     hl, de
        pop     de

        call    do_w_plot                   ; (-r,-cx)

        ld      hl, (cxl)
        inc     hl
        ld      (cxl), hl
        jp      l9905


;    SECTION smc_clib

do_w_plot:
        jp      (ix)


SECTION bss_graphics


x0l:
        defb    0
x0h:
        defb    0

y0l:
        defb    0
y0h:
        defb    0

rlv:
        defb    0
rh: defb    0

cxl:
        defb    0
cxh:
        defb    0

dal:
        defb    0
dahi:
        defb    0

ENDIF
