IF !__CPU_INTEL__ & !__CPU_GBZ80__ & !__CPU_RABBIT__ & !__CPU_Z180__
;Vortex Tracker II v1.0 PT3 player for ZX Spectrum
;ROM version (specially for Axor)
;(c)2004,2007 S.V.Bulba <vorobey@mail.khstu.ru>
;http://bulba.untergrund.net (http://bulba.at.kz)

        MODULE zx__pt3_core_state
DEFC PT3_ORIGIN = 0
INCLUDE "audio/z80/pt3.inc"

SECTION data_psg
PUBLIC zx__pt3_state
PUBLIC zx__pt3_ay_registers

; Contiguous writable storage for the Vortex player, initially silent.
zx__pt3_state:
        DEFS PT3_STATE_END
DEFC zx__pt3_ay_registers = zx__pt3_state+AYREGS
ENDIF
