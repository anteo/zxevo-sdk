; ZX AY output backend for the z88dk Vortex Tracker II PT3 player.
; Adapted from z88dk/libsrc/target/zx/sound/ay/asm_vt2_hardware_out.asm.

SECTION code_sound_ay

PUBLIC  zx__pt3_ay_out
PUBLIC  zx__pt3_ay_out_from_a
EXTERN  zx__pt3_ay_registers


zx__pt3_ay_out:
        XOR     A
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
