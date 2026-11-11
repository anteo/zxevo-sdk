; Self-authored minimal PT3 module used by the real z88dk player and AY backend.
; Its layout follows the Pro Tracker 3.7 module format.

SECTION rodata_user

PUBLIC _audio_pt3_module
_audio_pt3_module:
        DEFM    "Vortex Tracker II 1.0 module:ZX audio test"
        DEFS    99-($-_audio_pt3_module),0
        DEFB    1                       ; Sound Tracker note table
        DEFB    1                       ; one tick per tracker line
        DEFB    1                       ; one position
        DEFB    0                       ; loop to first position
        DEFW    audio_pt3_patterns-_audio_pt3_module
        DEFW    0                       ; sample 0 unused
        DEFW    audio_pt3_sample1-_audio_pt3_module
        DEFS    30*2,0                  ; samples 2..31
        DEFS    16*2,0                  ; ornaments 0..15
        DEFB    0,$ff                   ; one position, then end marker

audio_pt3_patterns:
        DEFW    audio_pt3_track_a-_audio_pt3_module
        DEFW    audio_pt3_track_b-_audio_pt3_module
        DEFW    audio_pt3_track_c-_audio_pt3_module

audio_pt3_track_a:
        DEFB    $b1,1,$d1,$80           ; one row per tick, sample 1, note
        DEFB    $84,$87,$8c,$87,$84,$80,$8c
        DEFB    0                       ; end pattern, loop position list
audio_pt3_track_b:
        DEFB    $b1,1,$c0               ; one row per tick, release channel
        DEFB    $d0,$d0,$d0,$d0,$d0,$d0,$d0
audio_pt3_track_c:
        DEFB    $b1,1,$c0
        DEFB    $d0,$d0,$d0,$d0,$d0,$d0,$d0

audio_pt3_sample1:
        DEFB    0,1                     ; loop at row 0, one row
        DEFB    $01,$8f                 ; no envelope; volume 15, tone on, noise off
        DEFW    0                       ; no tone shift

