        MODULE ts_copper_control
SECTION code_clib
PUBLIC _ts_copper_start
PUBLIC _ts_copper_stop

; Start at a valid list address, or stop with the hardware FFh command.
; Fastcall L = first word on start. Start returns status in L.
; Clobber AF/BC/HL, preserve DE/IX/IY.
_ts_copper_start:
        ld a,l
        cp 0ffh
        jr z,@invalid
        ld bc,14afh
        out (c),a
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret

_ts_copper_stop:
        ld bc,14afh
        ld a,0ffh
        out (c),a
        ret
