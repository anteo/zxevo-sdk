        MODULE zx_ayfx_stop
SECTION code_sound_ay
PUBLIC _zx_ayfx_stop
EXTERN zx__ayfx_channels
INCLUDE "audio/z80/ayfx.inc"

; Release all effect channels and silence the currently selected AY.
;
; memset(channels,0,sizeof(channels));
; AY[8]=AY[9]=AY[10]=0; AY[7] |= 0x3f;
;
; No arguments/result. AF/BC/DE/HL volatile; IX/IY and IFF preserved.
; Caller owns the AY and serializes against frame. Preserve mixer bits 6/7
; because they control AY I/O ports rather than tone/noise channels.
_zx_ayfx_stop:
        ld hl,zx__ayfx_channels
        ld de,zx__ayfx_channels+1
        ld bc,AFX_CHANNEL_BYTES-1
        xor a
        ld (hl),a
        ldir
        ld c,0fdh
        ld d,0
        ld a,8
mute:
        ld b,0ffh
        out (c),a
        ld b,0bfh
        out (c),d
        inc a
        cp 11
        jr nz,mute
        ld b,0ffh
        ld a,7
        out (c),a
        in a,(c)
        or 3fh
        ld b,0bfh
        out (c),a
        ret
