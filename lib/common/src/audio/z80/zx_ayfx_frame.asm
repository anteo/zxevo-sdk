        MODULE zx_ayfx_frame
SECTION code_sound_ay
PUBLIC _zx_ayfx_frame
EXTERN zx__ayfx_channels
INCLUDE "audio/z80/ayfx.inc"

; Decode one frame per active AFB channel and overlay it on the selected AY.
;
; for (channel=0; channel<3; ++channel) {
;     if (!state[channel].stream) continue;
;     flags=*stream++;
;     if (flags & 0x20) { tone=read_le16(stream); stream+=2; }
;     if (flags & 0x40) {
;         noise=*stream++;
;         if (noise>=32) { stream=NULL; flags=0x90; volume=0; render(); continue; }
;     }
;     age=min(age+1,65535); volume=clamp((flags&15)+adjustment,0,15);
;     render(); // cached tone, optional noise, amplitude and tone/noise mixer
; }
;
; No arguments/result. AF/BC/DE/HL volatile, IX/IY and IFF preserved.
; Caller serializes init/play/stop and keeps player state and streams mapped.
; Call PT3 before this tick to overlay effects on a shared chip; select the
; intended TurboSound chip before entry. AY's noise register is chip-global.
; Main loop saves BC (remaining channels, channel index) around each decode.
; Within decode: IX=descriptor, D=channel, E=flags, HL=stream then scratch.
_zx_ayfx_frame:
        push ix
        ld ix,zx__ayfx_channels
        ld bc,0300h
frame_loop:
        push bc
        ld d,c
        call channel_frame
        ld bc,AFX_CHANNEL_SIZE
        add ix,bc
        pop bc
        inc c
        djnz frame_loop
        pop ix
        ret

channel_frame:
        ld l,(ix+AFX_PTR_LO)
        ld h,(ix+AFX_PTR_HI)
        ld a,h
        or l
        ret z
        ld e,(hl)
        inc hl
        bit 5,e
        jr z,noise
        ld a,(hl)
        inc hl
        ld (ix+AFX_TONE_LO),a
        ld a,(hl)
        inc hl
        ld (ix+AFX_TONE_HI),a
noise:
        bit 6,e
        jr z,advance
        ld a,(hl)
        inc hl
        cp 32
        jr nc,ended
        ld (ix+AFX_NOISE),a
advance:
        ld (ix+AFX_PTR_LO),l
        ld (ix+AFX_PTR_HI),h
        inc (ix+AFX_AGE_LO)
        jr nz,volume
        inc (ix+AFX_AGE_HI)
        jr nz,volume
        ; Saturation avoids wrapping an old effect back to youngest.
        dec (ix+AFX_AGE_LO)
        dec (ix+AFX_AGE_HI)
volume:
        ld a,e
        and 15
        add a,(ix+AFX_VOLUME)
        bit 7,a
        jr z,positive
        xor a
positive:
        cp 16
        jr c,volume_ready
        ld a,15
volume_ready:
        ld h,a
        jr render
ended:
        xor a
        ld (ix+AFX_PTR_LO),a
        ld (ix+AFX_PTR_HI),a
        ld h,a
        ld e,90h                    ; disable tone (bit 4) and noise (bit 7)

; Output cached tone even when this frame omits it: a PT3 tick may have
; overwritten the hardware registers since the previous effect frame.
render:
        ld a,d
        add a,a
        ld bc,0fffdh
        out (c),a
        ld b,0bfh
        ld l,(ix+AFX_TONE_LO)
        out (c),l
        inc a
        ld b,0ffh
        out (c),a
        ld b,0bfh
        ld l,(ix+AFX_TONE_HI)
        out (c),l
        bit 6,e
        jr z,amplitude
        ld a,6
        ld b,0ffh
        out (c),a
        ld b,0bfh
        ld l,(ix+AFX_NOISE)
        out (c),l
amplitude:
        ld a,d
        add a,8
        ld b,0ffh
        out (c),a
        ld b,0bfh
        out (c),h

; AFB tone/noise disable bits 4/7 become AY mixer bits n/(n+3).
; Mask only that channel; preserve all other channels and I/O bits 6/7.
;
; mask=9<<channel; bits=((flags>>4)&9)<<channel;
; AY[7]=(AY[7]&~mask)|bits;
;
        ld a,e
        rrca
        rrca
        rrca
        rrca
        and 9
        ld h,a
        ld l,9
        ld a,d
        or a
        jr z,mixer
shift:
        sla h
        sla l
        dec a
        jr nz,shift
mixer:
        ld a,l
        cpl
        ld l,a
        ld a,7
        ld b,0ffh
        out (c),a
        in a,(c)
        and l
        or h
        ld b,0bfh
        out (c),a
        ret
