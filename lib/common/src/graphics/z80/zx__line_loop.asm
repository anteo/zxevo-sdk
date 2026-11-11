        MODULE zx__line_loop
SECTION code_graphics
PUBLIC zx__line_run
PUBLIC zx__line_init
PUBLIC zx__line_start
PUBLIC zx__line_major, zx__line_minor, zx__line_last
PUBLIC zx__line_major_delta, zx__line_minor_delta
PUBLIC zx__line_major_step, zx__line_minor_step, zx__line_error

; Initialize the shared raster state from two signed endpoints. Pick the
; axis with the larger unsigned delta and keep the original direction.
;
; dx = abs(x1 - x0); dy = abs(y1 - y0);
; state = dy > dx ? y_major_state : x_major_state;
; state.error = state.major_delta / 2;
;
; IX points at saved IX with x0 +4, y0 +6, x1 +8, y1 +10. Return the
; major-axis flag in A. Preserve IX/IY, clobber flags and BC/DE/HL.
zx__line_init:
        ld l,(ix+4)
        ld h,(ix+5)
        ld e,(ix+8)
        ld d,(ix+9)
        call zx__line_delta
        ld (zx__line_major_delta),hl
        ld (zx__line_major_step),bc

        ld l,(ix+6)
        ld h,(ix+7)
        ld e,(ix+10)
        ld d,(ix+11)
        call zx__line_delta
        ld (zx__line_minor_delta),hl
        ld (zx__line_minor_step),bc

        ex de,hl
        ld hl,(zx__line_major_delta)
        or a
        sbc hl,de
        ld a,0
        jr nc,zx__line_load_points
        ld hl,(zx__line_major_delta)
        ld (zx__line_minor_delta),hl
        ld (zx__line_major_delta),de
        ld hl,(zx__line_major_step)
        ld (zx__line_minor_step),hl
        ld (zx__line_major_step),bc
        inc a

zx__line_load_points:
        ld (zx__line_y_major),a
        ld l,(ix+4)
        ld h,(ix+5)
        ld e,(ix+6)
        ld d,(ix+7)
        ld c,(ix+8)
        ld b,(ix+9)
        or a
        jr z,zx__line_store_points
        ex de,hl
        ld c,(ix+10)
        ld b,(ix+11)
zx__line_store_points:
        ld (zx__line_major),hl
        ld (zx__line_minor),de
        ld (zx__line_last),bc
        ld hl,(zx__line_major_delta)
        srl h
        rr l
        ld (zx__line_error),hl
        ret

; Draw from the original endpoints using the writer in HL. The caller
; guarantees safe coordinates for that writer.
; SDCC x0 +2, y0 +4, x1 +6, y1 +8. Preserve IX/IY, clobber AF/BC/DE/HL.
zx__line_run:
        push ix
        ld ix,0
        add ix,sp
        push hl                      ; retain the writer across initialization
        call zx__line_init
        pop hl

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

; Signed HL=start, DE=end. Return unsigned HL=abs(end-start) and BC=step.
; Flipping both sign bits makes borrow a signed ordering test while leaving
; the difference modulo 65536 intact. Clobber AF/DE.
zx__line_delta:
        ld a,h
        xor 80h
        ld h,a
        ld a,d
        xor 80h
        ld d,a
        or a
        sbc hl,de
        ld bc,-1
        ret nc
        xor a
        sub l
        ld l,a
        sbc a,a
        sub h
        ld h,a
        ld bc,1
        ret

SECTION bss_graphics
; Shared with the slow clipper. Both paths initialize these fields in place.
zx__line_major:       defw 0
zx__line_minor:       defw 0
zx__line_last:        defw 0
zx__line_major_delta: defw 0
zx__line_minor_delta: defw 0
zx__line_major_step:  defw 0
zx__line_minor_step:  defw 0
zx__line_error:       defw 0
zx__line_y_major:     defb 0
