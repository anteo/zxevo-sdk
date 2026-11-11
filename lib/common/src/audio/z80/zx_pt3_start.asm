        MODULE zx_pt3_start

SECTION code_sound_ay
PUBLIC _zx_pt3_start
EXTERN _zx__pt3_enabled

; Set playback_enabled=1; the next explicit play tick advances music.
; No arguments/result; A changes, all other registers and flags are preserved.
; Initialize the player before enabling it.
_zx_pt3_start:
        ld a,1
        ld (_zx__pt3_enabled),a
        ret
