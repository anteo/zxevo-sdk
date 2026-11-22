        MODULE zx__line_init
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
PUBLIC zx__line_init

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
