        MODULE zx__scroll_linear_plane
SECTION code_clib
PUBLIC zx__scroll_linear_plane
EXTERN zx__fill_bytes

; Moves the surviving bytes toward the start of a linear plane and fills the
; vacated tail.
;
; C model:
;
;   assert(0 < displacement && displacement <= size);
;   memmove(base, base + displacement, size - displacement);
;   memset(base + size - displacement, blank, displacement);
;
; HL = CPU base, DE = byte displacement, BC = plane size, A = blank.
; A prepared lease keeps the writable range visible; preserve IX/IY and clobber
; AF/BC/DE/HL. Stack saves blank/displacement/base (six bytes) while calculating
; the copy count. Ascending copy is overlap-safe because destination < source.
zx__scroll_linear_plane:
        push af
        push de
        push hl
        ld h,b
        ld l,c
        or a
        sbc hl,de
        ld b,h
        ld c,l                       ; bytes that remain visible
        pop hl
        ex de,hl                     ; HL=displacement, DE=destination base
        add hl,de                    ; source base
        ld a,b
        or c
        jr z,@fill                   ; a full-height scroll skips zero-count LDIR
        ldir                         ; DE now points at the exposed tail
@fill:
        pop bc                       ; exposed byte count
        pop af
        ex de,hl                     ; HL=tail start
        jp zx__fill_bytes
