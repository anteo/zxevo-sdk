        MODULE zx__clip_extent
SECTION code_clib
PUBLIC zx__clip_extent
EXTERN zx__clip_axis

; Clip an origin and signed extent to an axis, returning inclusive endpoints.
;
; if (size <= 0) return empty;
; return clip_axis(start, min(start + size - 1, INT16_MAX), limit);
;
; HL=start, DE=size, BC=positive limit. Return HL=first, DE=last, carry if
; empty. Preserve BC/IX/IY. Save the original start during endpoint arithmetic.
zx__clip_extent:
        ld a,d
        or a
        jp m,@empty
        or e
        jr z,@empty
        push hl
        dec de
        adc hl,de                    ; OR cleared carry, DEC DE preserves it
        jp po,@endpoint
        ld hl,7fffh
@endpoint:
        ex de,hl
        pop hl
        jp zx__clip_axis
@empty:
        scf
        ret
