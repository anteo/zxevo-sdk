        MODULE  bc__circle_loop
SECTION code_graphics
PUBLIC  _bc__circle_loop
EXTERN  _bc_draw_callback

;-------------------------------------------------------------------------------
; void bc__circle_loop(int cx, int cy, int radius)
; Default SDCC convention: cx at SP+2, cy SP+4, radius SP+6.
;-------------------------------------------------------------------------------
;
; Draws a circle outline by plotting eight symmetric points for each midpoint
; step.
;
; Model:
;
; x=radius; y=0; error=1-radius;
; while (x>=y) { plot_eight_symmetry_points(cx,cy,x,y); ++y;
;     if (error<0) error+=2*y+1; else { --x; error+=2*(y-x)+1; }
; }
;
; Caller validates nonnegative radius, representable 16-bit intermediate values,
; and selects the native clipped/unclipped writer under an active lease.
; AF/BC/DE/HL volatile, IX saved, IY preserved by callback. State and generated
; symmetry points live in module BSS; the walk is non-reentrant. Coincident
; symmetry points are still emitted, matching this implemented loop.
_bc__circle_loop:
        push    ix
        ld      ix,2
        add     ix,sp
        ld      e,(ix+2)
        ld      d,(ix+3)
        ld      (bc_circle_cx),de
        ld      e,(ix+4)
        ld      d,(ix+5)
        ld      (bc_circle_cy),de
        ld      e,(ix+6)
        ld      d,(ix+7)
        ld      (bc_circle_x),de
        ld      hl,1
        or      a
        sbc     hl,de
        ld      (bc_circle_err),hl
        ld      hl,0
        ld      (bc_circle_y),hl
        ld      ix,(_bc_draw_callback)

circle_loop:
        ld      hl,(bc_circle_x)
        ld      de,(bc_circle_y)
        or      a
        sbc     hl,de
        jp      m,circle_done

        ld      hl,(bc_circle_cx)
        ld      de,(bc_circle_x)
        add     hl,de
        ld      (bc_circle_cxp),hl
        ld      hl,(bc_circle_cx)
        or      a
        sbc     hl,de
        ld      (bc_circle_cxm),hl

        ld      hl,(bc_circle_cy)
        ld      de,(bc_circle_y)
        add     hl,de
        ld      (bc_circle_cyp),hl
        ld      hl,(bc_circle_cy)
        or      a
        sbc     hl,de
        ld      (bc_circle_cym),hl

        ld      hl,(bc_circle_cx)
        ld      de,(bc_circle_y)
        add     hl,de
        ld      (bc_circle_cxy_p),hl
        ld      hl,(bc_circle_cx)
        or      a
        sbc     hl,de
        ld      (bc_circle_cxy_m),hl

        ld      hl,(bc_circle_cy)
        ld      de,(bc_circle_x)
        add     hl,de
        ld      (bc_circle_cyx_p),hl
        ld      hl,(bc_circle_cy)
        or      a
        sbc     hl,de
        ld      (bc_circle_cyx_m),hl

        ld      hl,(bc_circle_cxp)
        ld      de,(bc_circle_cyp)
        call    bc_circle_cb
        ld      hl,(bc_circle_cxy_p)
        ld      de,(bc_circle_cyx_p)
        call    bc_circle_cb
        ld      hl,(bc_circle_cxy_m)
        ld      de,(bc_circle_cyx_p)
        call    bc_circle_cb
        ld      hl,(bc_circle_cxm)
        ld      de,(bc_circle_cyp)
        call    bc_circle_cb
        ld      hl,(bc_circle_cxm)
        ld      de,(bc_circle_cym)
        call    bc_circle_cb
        ld      hl,(bc_circle_cxy_m)
        ld      de,(bc_circle_cyx_m)
        call    bc_circle_cb
        ld      hl,(bc_circle_cxy_p)
        ld      de,(bc_circle_cyx_m)
        call    bc_circle_cb
        ld      hl,(bc_circle_cxp)
        ld      de,(bc_circle_cym)
        call    bc_circle_cb

        ld      hl,(bc_circle_y)
        inc     hl
        ld      (bc_circle_y),hl
        ld      a,(bc_circle_err+1)
        or      a
        jp      m,circle_err_neg
        ld      hl,(bc_circle_x)
        dec     hl
        ld      (bc_circle_x),hl
        ld      hl,(bc_circle_y)
        ld      de,(bc_circle_x)
        or      a
        sbc     hl,de
        add     hl,hl
        inc     hl
        ld      de,(bc_circle_err)
        add     hl,de
        ld      (bc_circle_err),hl
        jp      circle_loop
circle_err_neg:
        ld      hl,(bc_circle_y)
        add     hl,hl
        inc     hl
        ld      de,(bc_circle_err)
        add     hl,de
        ld      (bc_circle_err),hl
        jp      circle_loop

circle_done:
        pop     ix
        ret

; Native callback bridge: IX is a non-NULL writer, HL=x,DE=y. Tail-enter
; the writer using its existing return address. Writer must preserve IX/IY;
; AF/BC/DE/HL are volatile and no C argument block is constructed.
bc_circle_cb:
        jp      (ix)

SECTION bss_graphics
bc_circle_cx:    defw 0
bc_circle_cy:    defw 0
bc_circle_x:     defw 0
bc_circle_y:     defw 0
bc_circle_err:   defw 0
bc_circle_cxp:   defw 0
bc_circle_cxm:   defw 0
bc_circle_cyp:   defw 0
bc_circle_cym:   defw 0
bc_circle_cxy_p: defw 0
bc_circle_cxy_m: defw 0
bc_circle_cyx_p: defw 0
bc_circle_cyx_m: defw 0
