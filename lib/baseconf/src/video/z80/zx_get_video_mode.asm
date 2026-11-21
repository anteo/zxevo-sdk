        MODULE zx_get_video_mode
SECTION code_clib
PUBLIC _zx_get_video_mode
PUBLIC _bc__video_read_mode_and_eff7
PUBLIC bc__video_read_mode_regs
EXTERN bc__mem_readback_register_regs

; Return the sampled mode in L and EFF7 in H for C callers.
; SDCC no arguments. Preserve IX/IY, clobber AF/BC/DE/HL.
_bc__video_read_mode_and_eff7:
        call bc__video_read_mode_regs
        ld h,b
        ret

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
; The readback helper preserves E, which holds the first register's mode bits.
_zx_get_video_mode:
bc__video_read_mode_regs:
        ld b,0Ch
        call bc__mem_readback_register_regs
        ld a,l
        and 7
        ld e,a
        ld b,0Bh
        call bc__mem_readback_register_regs
        ld b,l

        ld a,e
        cp 3
        ld a,l                       ; EFF7, preserving the mode comparison
        jr z,@zx_layout
        and 21h
        ld h,0
        ld l,0FFh                    ; BC_VIDEO_UNKNOWN
        ret nz
        ld d,0
        ld hl,bc_video_mode_by_xx77
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

SECTION rodata_clib
; xx77 modes 0/2/6/7 are ATM320/ATM640/ATM text/EVO text respectively.
bc_video_mode_by_xx77:
        defb 3,0FFh,4,0FFh,0FFh,0FFh,5,6

PUBLIC _bc__video_first_screen_pages
; ZX, Multicolor, Pentagon, ATM320, ATM640, ATM text and Evo text.
; Screen 1 adds two to each of these first physical pages.
_bc__video_first_screen_pages:
        defb 5,5,4,1,1,1,8
