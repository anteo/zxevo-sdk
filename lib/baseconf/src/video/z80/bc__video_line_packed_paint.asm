IFDEF BASECONF_VIDEO_PRIMITIVE_PACKED
        MODULE bc__video_line_packed_paint
SECTION code_clib
PUBLIC bc__video_line_packed_paint
EXTERN zx__ink
EXTERN zx__paper
EXTERN bc__video_packed_pixels_regs

; Return B = full-pair AND mask, C = encoded XOR bits. Preserve HL/IX/IY.
; Packing is a bit permutation, so XOR never needs to unpack either pixel.
;
; Encodes the ink or paper operation as byte masks that can paint both pixels
; in a packed pair.
;
; Model:
;
; color=(operation==CLEAR)?paper:ink; XOR=pack(color,color);
; AND=(operation==XOR)?0xff:0;
;
; The normalized IX frame supplies op +10; uses current global ink/paper.
; Full-pair update is (old&AND)^XOR. The pack permutation makes color XOR
; linear in the physical bits; no neighbour decode/repack or page changes.
bc__video_line_packed_paint:
        ld a,(ix+10)
        cp 1
        ld a,(zx__ink)
        jr nz,@color
        ld a,(zx__paper)
@color:
        ld e,a
        ld d,a
        call bc__video_packed_pixels_regs
        ld c,a
        ld b,0
        ld a,(ix+10)
        cp 2
        ret nz
        dec b
        ret
ENDIF
