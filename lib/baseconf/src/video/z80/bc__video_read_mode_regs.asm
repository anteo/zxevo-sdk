        MODULE bc__video_read_mode_regs
INCLUDE "memory/readback.inc"
EXTERN bc__video_mode_by_xx77
SECTION code_clib
PUBLIC bc__video_read_mode_regs

; Decode the live FPGA video mode. Return BC_VIDEO_UNKNOWN for undocumented
; combinations of the mode register and EFF7 layout bits.
; Model:
;
; mode = readback(0x0c) & 7;
; layout = readback(0x0b) & 0x21;
; if (mode != 3) return layout ? BC_VIDEO_UNKNOWN : mode_by_xx77[mode];
; if (layout == 0x21) return BC_VIDEO_UNKNOWN;
; if (layout & 1) return BC_VIDEO_PENTAGON_256;
; return layout ? BC_VIDEO_ZX_MULTICOLOR : BC_VIDEO_ZX_256;
;
; SDCC no arguments, result in HL. Preserve IX/IY, clobber AF/BC/DE/HL.
; Register entry also returns the sampled EFF7 byte in B.
; E holds the first register's mode bits across the second read.
bc__video_read_mode_regs:
        BC_MEM_READBACK 0Ch, a
        and 7
        ld e,a
        BC_MEM_READBACK 0Bh, b

        ld a,e
        cp 3
        ld a,b                       ; EFF7, preserving the mode comparison
        jr z,@zx_layout
        and 21h
        ld h,0
        ld l,0FFh                    ; BC_VIDEO_UNKNOWN
        ret nz
        ld d,0
        ld hl,bc__video_mode_by_xx77
        add hl,de
        ld l,(hl)
        ld h,0
        ret

@zx_layout:
        ld h,0
        and 21h
        ld l,0                       ; BC_VIDEO_ZX_256
        ret z
        cp 21h
        ld l,0FFh
        ret z
        and 1
        ld l,1                       ; BC_VIDEO_ZX_MULTICOLOR
        ret z
        inc l                        ; BC_VIDEO_PENTAGON_256
        ret
