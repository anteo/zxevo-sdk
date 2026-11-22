        MODULE zx__line_start
EXTERN zx__line_error
EXTERN zx__line_last
EXTERN zx__line_major
EXTERN zx__line_major_delta
EXTERN zx__line_major_step
EXTERN zx__line_minor
EXTERN zx__line_minor_delta
EXTERN zx__line_minor_step
EXTERN zx__line_y_major
SECTION code_graphics
PUBLIC zx__line_start

; Emit one pixel per major-axis coordinate. Strict comparison retains the
; original Bresenham tie rule in both directions.
;
; for (;;) {
;     plot(major, minor, y_major);
;     if (major == last) break;
;     major += major_step;
;     if (error < minor_delta) { minor += minor_step; error += major_delta; }
;     error -= minor_delta;
; }
;
; Enter with initialized BSS and saved IX on top of the return address.
; HL is the writer address. The writer takes HL=x and DE=y and preserves
; IX/IY. The state cannot be used recursively.
zx__line_start:
        push hl
        pop ix
zx__line_loop:
        ld hl,(zx__line_major)
        ld de,(zx__line_minor)
        ld a,(zx__line_y_major)
        or a
        jr z,zx__line_plot
        ex de,hl
zx__line_plot:
        call zx__line_cb
        ld hl,(zx__line_major)
        ld de,(zx__line_last)
        or a
        sbc hl,de
        jr z,zx__line_done
        add hl,de
        ld de,(zx__line_major_step)
        add hl,de
        ld (zx__line_major),hl

        ld hl,(zx__line_error)
        ld de,(zx__line_minor_delta)
        or a
        sbc hl,de
        jr nc,zx__line_store_error
        ld de,(zx__line_major_delta)
        add hl,de                    ; repair unsigned borrow modulo 65536
        ld (zx__line_error),hl
        ld hl,(zx__line_minor)
        ld de,(zx__line_minor_step)
        add hl,de
        ld (zx__line_minor),hl
        jr zx__line_loop
zx__line_store_error:
        ld (zx__line_error),hl
        jr zx__line_loop
zx__line_done:
        pop ix
        ret

zx__line_cb:
        jp (ix)
