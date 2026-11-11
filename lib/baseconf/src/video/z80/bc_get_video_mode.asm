        MODULE bc_get_video_mode
SECTION code_clib
PUBLIC _bc_get_video_mode
EXTERN bc__mem_readback_register_regs

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
; SDCC no arguments, result in L. Preserve IX/IY, clobber AF/BC/DE/HL.
; The readback helper preserves E, which holds the first register's mode bits.
_bc_get_video_mode:
        ld b,0Ch
        call bc__mem_readback_register_regs
        ld a,l
        and 7
        ld e,a
        ld b,0Bh
        call bc__mem_readback_register_regs

        ld a,e
        cp 3
        ld a,l                       ; EFF7, preserving the mode comparison
        jr z,@zx_layout
        and 21h
        ld l,0FFh                    ; BC_VIDEO_UNKNOWN
        ret nz
        ld d,0
        ld hl,bc_video_mode_by_xx77
        add hl,de
        ld l,(hl)
        ret

@zx_layout:
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

SECTION rodata_clib
; xx77 modes 0/2/6/7 are ATM320/ATM640/ATM text/EVO text respectively.
bc_video_mode_by_xx77:
        defb 3,0FFh,4,0FFh,0FFh,0FFh,5,6
