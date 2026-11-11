        MODULE bc__text_encode_attribute

SECTION code_clib
PUBLIC _bc__text_encode_attribute
EXTERN zx__ink
EXTERN zx__paper
EXTERN generic_console_flags

; Return the hardware-text attribute in L. Inverse swaps ink and paper.
; Bits 0..2 are ink, 3..5 paper, 6 ink bright, 7 paper bright.
; Preserve DE/IX/IY, including the character offset held by the text writer.
;
; Encodes the current ink and paper into a hardware text attribute, swapping
; them for inverse video.
;
; Model:
;
; ink=video_ink&15; paper=video_paper&15; if (inverse) swap(ink,paper);
; return (ink&7)|((paper&7)<<3)|((ink&8)<<3)|((paper&8)<<4);
;
; No lease or arguments; AF/BC/HL volatile, DE/IX/IY preserved. Bit 6 is
; independent ink brightness; bit 7 is paper brightness, not flashing.
_bc__text_encode_attribute:
        ld a,(zx__ink)
        ld b,a
        ld a,(zx__paper)
        ld c,a
        ld a,(generic_console_flags)
        rlca
        jr nc,@colors
        ld a,b
        ld b,c
        ld c,a
@colors:
        ld a,b
        and 7
        bit 3,b
        jr z,@ink_ready
        or 40h
@ink_ready:
        ld l,a
        ld a,c
        and 7
        rlca
        rlca
        rlca
        or l
        bit 3,c
        jr z,@done
        or 80h
@done:
        ld l,a
        ret
