        MODULE bc__video_pixel_mask
SECTION code_clib
PUBLIC bc__video_pixel_mask
EXTERN zx__edge_masks

; A = pixel bit 0..7. Return A = 80h >> bit, using the same edge table.
; Clobber DE/HL; preserve BC/IX/IY.
;
; Returns the mask for one pixel position in an MSB-first bitmap byte.
;
; Model:
;
; return edge[bit]^edge[bit+1]; /* equivalent to 0x80>>bit */
;
; Bit must be 0..7; the ninth table entry handles bit 7 without a special case.
; The helper is pure and performs no pixel access; ABI/preservation above.
bc__video_pixel_mask:
        ld e,a
        ld d,0
        ld hl,zx__edge_masks
        add hl,de
        ld a,(hl)
        inc hl
        xor (hl)
        ret
