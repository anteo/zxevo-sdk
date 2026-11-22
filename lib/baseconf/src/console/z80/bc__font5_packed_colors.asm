IFDEF BASECONF_VIDEO_TEXT_PACKED
        MODULE bc__font5_packed_colors
SECTION code_clib
PUBLIC bc__font5_packed_colors

; Build all four opaque pixel pairs for a Pentagon or ATM320 narrow glyph.
;
; ink_pair = pack(ink, ink); paper_pair = pack(paper, paper);
; diff = (ink_pair ^ paper_pair) & 0x47;
; return paper_pair, ink_pair, paper_pair ^ diff, ink_pair ^ diff;
;
; IX addresses the font callback frame (ink +11, paper +12). Return B=PP,
; C=II, H=IP and L=PI, with the left pixel named first. Clobber AF/DE.
bc__font5_packed_colors:
        ld a,(ix+11)
        call @both_fields
        ld c,a
        ld a,(ix+12)
        call @both_fields
        ld b,a
        xor c
        and 47h
        ld e,a
        xor c
        ld l,a
        ld a,e
        xor b
        ld h,a
        ret

; Duplicate the RGB bits in positions 0..2 and 3..5. Both brightness bits
; (6 and 7) follow color bit 3. Return the packed byte in A.
@both_fields:
        ld e,a
        and 7
        ld d,a
        rlca
        rlca
        rlca
        or d
        bit 3,e
        ret z
        or 0c0h
        ret
ENDIF
