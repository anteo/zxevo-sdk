        MODULE zx_pt3_mute

SECTION code_sound_ay
PUBLIC _zx_pt3_mute
EXTERN zx__pt3_core_mute

; Mute the AY channels now without changing playback_enabled.
; No arguments/result; IX is saved. AF/BC/DE/HL and player alternate registers
; are volatile; requires initialized/mapped player state.
_zx_pt3_mute:
        push ix
        call zx__pt3_core_mute
        pop ix
        ret
