        MODULE ts_irq_set_frame_position
SECTION code_clib
PUBLIC _ts_irq_set_frame_position

; Program a frame compare position and optional per-frame line increment.
;
; if (horizontal >= 224 || line >= FRAME_LINES || step >= 16)
;     return ZX_INVALID_ARGUMENT;
; if (FRAME_LINES == 262 && step) return ZX_UNSUPPORTED;
; OUT(0x22af, horizontal);
; OUT(0x23af, line & 255);
; OUT(0x24af, (line >> 8) | (step << 4));
; return ZX_OK;
;
; SDCC caller-clean horizontal at SP+2, line word at SP+3, step at SP+5.
; L = status. Frame IRQ must be disabled while programming the compare.
; Clobber AF/BC/DE/HL, preserve IX/IY.
_ts_irq_set_frame_position:
        ld hl,2
        add hl,sp
        ld e,(hl)
        ld a,e
        cp 224
        jr nc,@invalid
        inc hl
        ld c,(hl)
        inc hl
        ld b,(hl)
        inc hl
        ld a,b
        cp TSCONF_FRAME_LINES >> 8
        jr c,@step
        jr nz,@invalid
        ld a,c
        cp TSCONF_FRAME_LINES & 0ffh
        jr nc,@invalid
@step:
        ld a,(hl)
        cp 16
        jr nc,@invalid
IFDEF TSCONF_VIDEO_60HZ
        or a
        jr nz,@unsupported
ENDIF
        rlca
        rlca
        rlca
        rlca
        or b                         ; VSINTH has line bit 8 and increment in D7..D4
        ld d,a
        ld l,c
        ld bc,22afh
        out (c),e
        inc b
        out (c),l
        inc b
        out (c),d
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
IFDEF TSCONF_VIDEO_60HZ
@unsupported:
        ld l,5                       ; ZX_UNSUPPORTED
        ret
ENDIF
