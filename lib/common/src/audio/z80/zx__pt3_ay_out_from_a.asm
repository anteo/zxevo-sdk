        MODULE zx__pt3_ay_out_from_a
EXTERN zx__pt3_ay_registers
SECTION code_sound_ay
PUBLIC zx__pt3_ay_out_from_a
zx__pt3_ay_out_from_a:
ROUT_A0:
        LD      DE, $FFBF
        LD      BC, $FFFD
        LD      HL, zx__pt3_ay_registers
LOUT:
        OUT     (C), A
        LD      B, E
        OUTI
        LD      B, D
        INC     A
        CP      13
        JR      NZ, LOUT
        OUT     (C), A
        LD      A, (HL)
        AND     A
        RET     M
        LD      B, E
        OUT     (C), A
        RET
