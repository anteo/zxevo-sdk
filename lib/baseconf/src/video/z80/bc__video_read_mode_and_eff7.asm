        MODULE bc__video_read_mode_and_eff7
EXTERN bc__video_read_mode_regs
SECTION code_clib
PUBLIC _bc__video_read_mode_and_eff7

; Return the sampled mode in L and EFF7 in H for C callers.
; SDCC no arguments. Preserve IX/IY, clobber AF/BC/DE/HL.
_bc__video_read_mode_and_eff7:
        call bc__video_read_mode_regs
        ld h,b
        ret
