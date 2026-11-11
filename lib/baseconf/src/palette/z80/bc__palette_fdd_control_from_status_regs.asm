        MODULE bc__palette_fdd_control_from_status_regs
SECTION code_clib
PUBLIC bc__palette_fdd_control_from_status_regs

; Reconstruct FDD control from its status readback. Model:
;
; return (status ^ 0x10) & 0x1f;
;
; A = status, result in A and L. Preserve BC/DE/H/IX/IY, clobber AF/L.
; Bits 0..3 are copied and bit 4 has inverted polarity.
bc__palette_fdd_control_from_status_regs:
        xor 10h
        and 1Fh
        ld l,a
        ret
