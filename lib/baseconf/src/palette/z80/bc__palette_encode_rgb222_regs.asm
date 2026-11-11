        MODULE bc__palette_encode_rgb222_regs
SECTION code_clib
PUBLIC bc__palette_encode_rgb222_regs

; Encode the ATM RGB222 port byte. Model:
;
; bits = (g0<<7) | (r0<<6) | (b0<<5) | (g1<<4) | (r1<<1) | b1;
; return (uint8_t)~bits;
;
; E/D/C = red/green/blue, result in A and L. Preserve B/H/IX/IY,
; clobber AF/C/DE/L. Shift channel bits through carry in grbG00RB order.
; Inversion sets the two reserved FDD bits to one.
bc__palette_encode_rgb222_regs:
        xor a
        srl d                        ; g0
        rla
        srl e                        ; r0
        rla
        srl c                        ; b0
        rla
        srl d                        ; g1
        rla
        add a,a                      ; reserved FDD bits before inversion
        add a,a
        srl e                        ; r1
        rla
        srl c                        ; b1
        rla
        cpl
        ld l,a
        ret
