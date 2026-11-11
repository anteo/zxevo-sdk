        MODULE zx_pt3_play

SECTION code_sound_ay
PUBLIC _zx_pt3_play
EXTERN zx__pt3_core_play
EXTERN _zx__pt3_enabled

; Advances the PT3 player by one tick when playback is enabled.
;
; Model:
;
; if (playback_enabled) VT_PLAY();
;
; No arguments/result; call at the intended music frame rate after init.
; IX is saved around the player; AF/BC/DE/HL and player alternate registers
; are volatile. Player memory/module must remain mapped during the tick.
_zx_pt3_play:
        ld a,(_zx__pt3_enabled)
        or a
        ret z
        push ix
        call zx__pt3_core_play
        pop ix
        ret
