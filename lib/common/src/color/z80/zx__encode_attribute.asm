        MODULE zx__encode_attribute

SECTION code_clib
PUBLIC zx__encode_attribute

; E = foreground, D = background. Return the ZX attribute in A.
; Preserve BC/DE/HL/IX/IY. The two colors share the hardware bright bit.
;
; Encodes two palette indices as a ZX attribute with one brightness bit
; shared by ink and paper.
;
; Model:
;
; return (ink&7)|((paper&7)<<3)|(((ink|paper)&8)<<3);
;
; Either bright input makes both colors bright.
; Only AF changes; BC/DE/HL/IX/IY are preserved. This helper does not set flash.
zx__encode_attribute:
        push bc
        ld a,d
        and 7
        rlca
        rlca
        rlca
        ld c,a
        ld a,e
        and 7
        or c
        ld c,a
        ld a,e
        or d
        and 8
        rlca
        rlca
        rlca
        or c
        pop bc
        ret
