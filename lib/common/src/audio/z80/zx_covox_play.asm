SECTION code_clib
PUBLIC _zx_covox_play
PUBLIC _zx__covox_pcm8_block

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
        call pcm8_loop
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
        call pcm8_loop
        pop ix
        ret

; HL=source, DE=nonzero sample count, IXL=delay (1..255).
;
; Model:
;
; do { OUT(0x00fb,*samples++); if (!--length) break;
;      for (a=delay; a; --a) {} } while (1);
;
; Ordinary samples are spaced 64+14*delay T-states, excluding interrupt
; latency, memory waits and interbank call/remap overhead. BC remains 00FBh.
pcm8_loop:
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
