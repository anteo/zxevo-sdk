        MODULE zx_ayfx_play
SECTION code_sound_ay
PUBLIC _zx_ayfx_play
EXTERN zx__ayfx_table, zx__ayfx_count, zx__ayfx_channels
INCLUDE "audio/z80/ayfx.inc"

; Schedule an AFB effect on a free channel, otherwise replace the oldest.
;
; if (!count) return NOT_INITIALIZED;
; if (index>=count || volume < -15 || volume > 15) return INVALID_ARGUMENT;
; slot=table+2*index;
; stream=slot+1+read_le16(slot); // offsets are relative to their HIGH byte
; channel=first_inactive_or_oldest(channels);
; channel={stream, age:0, volume, tone:0, noise:0}; return OK;
;
; SDCC caller-clean index at SP+2, signed volume at SP+3; status HL.
; AF/BC/DE volatile, IX/IY preserved. Saves/disables INT while changing
; channel state; trusted bank and streams must remain mapped. During selection
; the stack holds saved IFF flags, IX, IY, volume in BC and stream pointer.
_zx_ayfx_play:
        ld a,(zx__ayfx_count)
        or a
        jp z,uninitialized
        ld b,a
        ld hl,2
        add hl,sp
        ld a,(hl)
        cp b
        jp nc,invalid
        ld e,a
        inc hl
        ld c,(hl)
        ld a,c
        add a,15
        cp 31
        jp nc,invalid
        ld a,i
        di
        push af
        push ix
        push iy
        push bc
        ld d,0
        ld hl,(zx__ayfx_table)
        add hl,de
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        add hl,de
        push hl
        ld ix,zx__ayfx_channels
        push ix
        pop iy
        ld de,0
        ld b,3
choose:
        ld a,(ix+AFX_PTR_LO)
        or (ix+AFX_PTR_HI)
        jr z,free_channel
        ld a,(ix+AFX_AGE_HI)
        cp d
        jr c,next
        jr nz,older
        ld a,(ix+AFX_AGE_LO)
        cp e
        jr c,next
older:
        ld e,(ix+AFX_AGE_LO)
        ld d,(ix+AFX_AGE_HI)
        push ix
        pop iy
next:
        push bc
        ld bc,AFX_CHANNEL_SIZE
        add ix,bc
        pop bc
        djnz choose
        push iy
        pop ix
free_channel:
        pop de
        pop bc
        ld (ix+AFX_PTR_LO),e
        ld (ix+AFX_PTR_HI),d
        ld (ix+AFX_VOLUME),c
        xor a
        ld (ix+AFX_AGE_LO),a
        ld (ix+AFX_AGE_HI),a
        ld (ix+AFX_TONE_LO),a
        ld (ix+AFX_TONE_HI),a
        ld (ix+AFX_NOISE),a
        pop iy
        pop ix
        pop af
        ld hl,0
        ret po
        ei
        ret
invalid:
        ld hl,1
        ret
uninitialized:
        ld hl,4
        ret
