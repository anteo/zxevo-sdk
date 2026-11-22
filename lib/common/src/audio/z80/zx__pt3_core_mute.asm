IF !__CPU_INTEL__ & !__CPU_GBZ80__ & !__CPU_RABBIT__ & !__CPU_Z180__
;Vortex Tracker II v1.0 PT3 player for ZX Spectrum
;ROM version (specially for Axor)
;(c)2004,2007 S.V.Bulba <vorobey@mail.khstu.ru>
;http://bulba.untergrund.net (http://bulba.at.kz)

        MODULE zx__pt3_core_mute
SECTION code_sound_ay
PUBLIC zx__pt3_core_mute
EXTERN zx__pt3_ay_registers
EXTERN zx__pt3_ay_out_from_a

; Silence all channels in the register image and on the AY.
zx__pt3_core_mute:
        LD A,$3F
        LD (zx__pt3_ay_registers+7),A
        XOR A
        LD H,A
        LD L,A
        LD (zx__pt3_ay_registers+8),A
        LD (zx__pt3_ay_registers+9),HL
        JP zx__pt3_ay_out_from_a
ENDIF
