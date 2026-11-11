        MODULE zx_pt3_stop

SECTION code_sound_ay
PUBLIC _zx_pt3_stop
EXTERN zx__pt3_core_mute
EXTERN _zx__pt3_enabled

; Stops future PT3 ticks and silences the AY channels immediately.
;
; Model:
;
; playback_enabled=0; VT_MUTE();
;
; No arguments/result. IX saved; AF/BC/DE/HL and player alternate registers
; volatile. Stops future ticks as well as silencing the current AY output.
_zx_pt3_stop:
        xor a
        ld (_zx__pt3_enabled),a
        push ix
        call zx__pt3_core_mute
        pop ix
        ret
