        MODULE bc__palette_encode_rgb222
SECTION code_clib
PUBLIC _bc__palette_encode_rgb222
EXTERN bc__palette_encode_rgb222_regs

; SDCC color by value: r/g/b bytes at SP+2/+3/+4, result in L.
; Tail adapter. Preserve B/IX/IY, clobber AF/C/DE/HL.
_bc__palette_encode_rgb222:
        ld hl,2
        add hl,sp
        ld e,(hl)                    ; red
        inc hl
        ld d,(hl)                    ; green
        inc hl
        ld c,(hl)                    ; blue
        jp bc__palette_encode_rgb222_regs
