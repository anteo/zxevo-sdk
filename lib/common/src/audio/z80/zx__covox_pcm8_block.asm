        MODULE zx__covox_pcm8_block
EXTERN zx__audio_pcm8_loop
SECTION code_clib
PUBLIC _zx__covox_pcm8_block

; Internal C entry with the same arguments, trusted nonzero count/delay.
; It deliberately emits no idle level between bank segments. IX/IY preserved.
_zx__covox_pcm8_block:
        ld hl,6
        add hl,sp
        ld a,(hl)
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
        ex de,hl
        call zx__audio_pcm8_loop
        pop ix
        ret
