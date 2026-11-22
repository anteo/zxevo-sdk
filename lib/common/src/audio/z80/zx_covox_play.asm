        MODULE zx_covox_play
EXTERN zx__audio_pcm8_loop
SECTION code_clib
PUBLIC _zx_covox_play

; Play unsigned PCM8 at port 00FBh and return the DAC to midpoint.
;
; Model:
;
; if (!samples || !length || !delay) return INVALID_ARGUMENT;
; pcm8_block(samples, length, delay); OUT(0x00fb,128); return OK;
;
; SDCC caller-clean: pointer SP+2, byte count SP+4, delay SP+6.
; HL=status; AF/BC/DE/HL volatile, IX/IY preserved, IFF unchanged.
; Samples must stay readable without wrapping the CPU address space.
_zx_covox_play:
        ld hl,6
        add hl,sp
        ld a,(hl)
        or a
        jr z,invalid
        push ix
        ld ixl,a
        ld hl,4
        add hl,sp
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ld a,h
        or l
        jr z,invalid_pop
        ld a,d
        or e
        jr z,invalid_pop
        ex de,hl
        call zx__audio_pcm8_loop
        ld a,128
        out (c),a
        pop ix
        ld hl,0
        ret
invalid_pop:
        pop ix
invalid:
        ld hl,1
        ret
