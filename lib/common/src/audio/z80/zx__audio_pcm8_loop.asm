        MODULE zx__audio_pcm8_loop
SECTION code_clib
PUBLIC zx__audio_pcm8_loop

; HL=source, DE=nonzero sample count, IXL=delay (1..255).
;
; Model:
;
; do { OUT(0x00fb,*samples++); if (!--length) break;
;      for (a=delay; a; --a) {} } while (1);
;
; Ordinary samples are spaced 64+14*delay T-states, excluding interrupt
; latency, memory waits and interbank call/remap overhead. BC remains 00FBh.
zx__audio_pcm8_loop:
        ld bc,$00fb
next_sample:
        ld a,(hl)
        out (c),a
        inc hl
        dec de
        ld a,d
        or e
        jr z,block_done
        ld a,ixl
wait_sample:
        dec a
        jp nz,wait_sample
        jp next_sample
block_done:
        ret
