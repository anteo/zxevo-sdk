        MODULE zx_ayfx_init
SECTION code_sound_ay
PUBLIC _zx_ayfx_init
EXTERN zx__ayfx_table, zx__ayfx_count
EXTERN _zx_ayfx_stop

; Select a trusted AFB bank and reset/silence the selected AY.
;
; if (!bank || bank[0]==0) return INVALID_ARGUMENT;
; count=bank[0]; table=bank+1; stop(); return OK;
;
; Fastcall HL=bank, status HL. AF/BC/DE volatile; IX/IY preserved.
; Bank must stay mapped; caller serializes with frame and owns selected AY.
_zx_ayfx_init:
        ld a,h
        or l
        jr z,invalid
        ld a,(hl)
        or a
        jr z,invalid
        ld (zx__ayfx_count),a
        inc hl
        ld (zx__ayfx_table),hl
        call _zx_ayfx_stop
        ld hl,0
        ret
invalid:
        ld hl,1
        ret
