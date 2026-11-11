        MODULE bc__video_packed_pixel_color_regs
SECTION code_clib
PUBLIC bc__video_packed_pixel_color_regs

; A = packed byte, E = right (zero/nonzero). Return A = index.
; Preserve HL/IX/IY; clobber AF/BC. DE is unchanged.
;
; Decodes the selected left or right pixel from a packed byte into its
; palette index.
;
; Model:
;
; return right ? ((packed>>3)&7)|((packed>>4)&8)
;              : (packed&7)|((packed>>3)&8);
;
; The right selector is zero/nonzero, not restricted to exactly one.
; Pure field extraction; no memory writes and no neighbouring-field dependence.
bc__video_packed_pixel_color_regs:
        ld c,a
        ld a,e
        or a
        ld a,c
        jr nz,@right
        and 7
        bit 6,c
        ret z
        or 8
        ret
@right:
        rrca
        rrca
        rrca
        and 7
        bit 7,c
        ret z
        or 8
        ret
