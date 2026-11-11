        MODULE zx__line_clip
SECTION code_graphics
PUBLIC zx__line_clip
EXTERN zx__clip_axis
EXTERN zx__line_init
EXTERN zx__line_skip
EXTERN zx__line_start
EXTERN zx__line_major, zx__line_minor, zx__line_last
EXTERN zx__line_major_delta, zx__line_minor_delta
EXTERN zx__line_major_step, zx__line_minor_step, zx__line_error

; Draw the visible part of a line with the original Bresenham phase.
;
; x_span = clip_span(x0,x1,width); y_span = clip_span(y0,y1,height);
; if (x_span.empty || y_span.empty) return;
; init_line_state(x0,y0,x1,y1);
; span = y_major ? y_span : x_span;
; if (major_step < 0) swap(span.first, span.last);
; skipped = abs(span.first - major);
; major = span.first; last = span.last;
; if (skipped) {
;     (advance, error) = line_skip(skipped, minor_delta, major_delta);
;     minor += minor_step * advance;
; }
; walk_line_state();
;
; SDCC endpoint words on the stack, HL=writer, BC=width, DE=height.
; Dimensions are positive signed words. Writer clips the minor axis.
; IX points at saved IX. Writer is saved at IX-2, followed by the height
; until the X span is clipped, then by the two sorted axis spans.
; Preserve IX/IY, clobber AF/BC/DE/HL. The line state is non-reentrant.
zx__line_clip:
        push ix
        ld ix,0
        add ix,sp
        push hl
        push de
        ld l,(ix+4)
        ld h,(ix+5)
        ld e,(ix+8)
        ld d,(ix+9)
        call zx__clip_axis
        jp c,@reject
        pop bc
        push hl
        push de
        ld l,(ix+6)
        ld h,(ix+7)
        ld e,(ix+10)
        ld d,(ix+11)
        call zx__clip_axis
        jr c,@reject
        push hl
        push de
        call zx__line_init

        ; Spans are sorted. Select the major axis before restoring direction.
        or a
        pop de                       ; y high
        pop hl                       ; y low
        pop bc                       ; x high
        jr nz,@y_major
        ld d,b
        ld e,c
        pop hl                       ; x low
        jr @span
@y_major:
        pop bc                       ; discard x low
@span:
        ld a,(zx__line_major_step+1)
        or a
        jr z,@forward
        ex de,hl
@forward:
        ld (zx__line_last),de
        ld de,(zx__line_major)
        ld (zx__line_major),hl
        jr z,@skipped
        ex de,hl
@skipped:
        ; Subtract in traversal order to get the full unsigned prefix length.
        sbc hl,de
        jr z,@draw
        ld bc,(zx__line_minor_delta)
        ld de,(zx__line_major_delta)
        call zx__line_skip
        ld (zx__line_error),de

        ld de,(zx__line_minor)
        ld a,(zx__line_minor_step+1)
        or a
        jr z,@advance
        ex de,hl
        sbc hl,de
        jr @store_minor
@advance:
        add hl,de
@store_minor:
        ld (zx__line_minor),hl
@draw:
        ld l,(ix-2)
        ld h,(ix-1)
        ld sp,ix
        jp zx__line_start

@reject:
        ld sp,ix
        pop ix
        ret
