; zx_status_t zx_covox_play(const uint8_t *samples, uint16_t length)
; Playback loop adapted from z88dk libsrc/classic/games/playzb4_dac.asm,
; based on SG C Tools 1.7, (C) 1993 Steve Goldsmith.
; Adapted for BaseConf on 2026-11-05: fixed port, SDCC entry and status,
; and correct handling of every nonzero 16-bit sample length.

SECTION code_clib

PUBLIC _zx_covox_play

defc ZX_COVOX_PORT = $00fb

; Plays a packed 4-bit sample buffer through Covox, sending the high nibble
; first and waiting until playback finishes.
;
; Model:
;
; if (!samples || !length) return INVALID_ARGUMENT;
; for (i=0; i<length; ++i) { delay(); OUT(0x00fb,samples[i]&0xf0);
;     delay(); OUT(0x00fb,(samples[i]<<4)&0xf0); } return OK;
;
; Caller-clean pointers/length at SP+2/+4, status in HL. Sample bytes stay
; readable for the blocking call. AF/BC/DE/HL volatile; IX/IY preserved.
; Counted delays depend on CPU speed and interrupt latency; IFF is unchanged.
; Length is decomposed into a first partial block and full 256-byte blocks;
; incrementing D when E!=0 fixes the original short/non-multiple-of-256 case.
_zx_covox_play:
        pop bc                      ; return address
        pop hl                      ; samples
        pop de                      ; length
        push de
        push hl
        push bc

        ld a,h
        or l
        jr z,bc_covox_play_invalid
        ld a,d
        or e
        jr z,bc_covox_play_invalid

    ; The original loop consumes E bytes, then 256 for each remaining D.
    ; Adjust D so a short buffer does not run through the address space.
        ld a,e
        or a
        jr z,bc_covox_play_ready
        inc d
bc_covox_play_ready:
        ld bc,ZX_COVOX_PORT

bc_covox_play_next:
        push bc
        ld b,31
bc_covox_play_delay_high:
        djnz bc_covox_play_delay_high
        pop bc

        ld a,(hl)
        and $f0
        out (c),a

        push bc
        ld b,31
bc_covox_play_delay_low:
        djnz bc_covox_play_delay_low
        pop bc

        ld a,(hl)
        rlca
        rlca
        rlca
        rlca
        and $f0
        out (c),a

        inc hl
        dec e
        jr nz,bc_covox_play_next
        dec d
        jr nz,bc_covox_play_next
        ld hl,0                     ; ZX_OK
        ret

bc_covox_play_invalid:
        ld hl,1                     ; ZX_INVALID_ARGUMENT
        ret
