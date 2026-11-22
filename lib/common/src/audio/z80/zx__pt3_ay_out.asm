        MODULE zx__pt3_ay_out
EXTERN zx__pt3_ay_out_from_a
SECTION code_sound_ay
PUBLIC zx__pt3_ay_out
; ZX AY output backend for the z88dk Vortex Tracker II PT3 player.
; Adapted from z88dk/libsrc/target/zx/sound/ay/asm_vt2_hardware_out.asm.

zx__pt3_ay_out:
        XOR     A
        jp zx__pt3_ay_out_from_a
