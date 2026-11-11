        MODULE zx__line_skip
SECTION code_graphics
PUBLIC zx__line_skip

; Jump over the invisible prefix of a Bresenham line and recover its phase.
;
; scaled = skipped * minor_delta + (major_delta - 1) / 2;
; return (scaled / major_delta, major_delta - 1 - scaled % major_delta);
;
; HL=skipped, BC=minor_delta, DE=major_delta. Return HL=minor steps, DE=error.
; Requires 0 < major_delta and minor_delta <= major_delta. Preserve IX/IY,
; clobber AF/BC. A counts bits, BC is quotient, DE is divisor, HL is remainder.
; IX points at the shifting copy of skipped, with minor_delta at IX+2.
zx__line_skip:
        push ix
        push bc
        push hl
        ld ix,0
        add ix,sp
        ld hl,0
        ld bc,0
        ld a,16
@bit:
        sla c
        rl b
        add hl,hl
        call @reduce
        sla (ix+0)
        rl (ix+1)
        jr nc,@next
        push bc
        ld c,(ix+2)
        ld b,(ix+3)
        add hl,bc
        pop bc
        call @reduce
@next:
        dec a
        jr nz,@bit

        ; Bias for strict error < minor_delta ties. Add it once after the
        ; product so the bit loop needs only a 17-bit partial remainder.
        push bc
        ld b,d
        ld c,e
        dec bc
        srl b
        rr c
        add hl,bc
        pop bc
        call @reduce

        ex de,hl
        dec hl
        or a
        sbc hl,de
        ex de,hl
        ld h,b
        ld l,c
        pop bc
        pop bc
        pop ix
        ret

; CF:HL is below 2*DE. Subtract DE at most once and increment the quotient
; when it fits. With carry set the wide subtraction always fits in HL.
@reduce:
        jr c,@wide
        sbc hl,de
        jr nc,@increment
        add hl,de
        ret
@wide:
        or a
        sbc hl,de
@increment:
        inc bc
        ret
