        MODULE zx_pt3_init

SECTION code_sound_ay
PUBLIC _zx_pt3_init
EXTERN zx__pt3_core_init
EXTERN _zx__pt3_enabled

; SDCC stack: return address, module pointer.
;
; Initializes the PT3 player from a module and leaves playback disabled.
;
; Model:
;
; if (!module) return INVALID_ARGUMENT;
; VT_INIT(module); playback_enabled=0; return OK;
;
; Caller keeps the PT3 module/player storage accessible for later frames.
; Status HL; AF/BC/DE/HL and player alternate registers volatile; IX/IY saved.
; The module pointer is consumed directly from the caller-clean SP+2 slot.
_zx_pt3_init:
        pop de
        pop hl
        push hl
        push de
        ld a,h
        or l
        jr z,zx_pt3_init_invalid
        push ix
        push iy
        call zx__pt3_core_init
        pop iy
        pop ix
        xor a
        ld (_zx__pt3_enabled),a
        ld hl,0                     ; ZX_OK
        ret

zx_pt3_init_invalid:
        ld hl,1                     ; ZX_INVALID_ARGUMENT
        ret
