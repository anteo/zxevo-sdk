        MODULE bc__draw_select
SECTION code_graphics
PUBLIC bc__draw_select_regs
IFDEF BASECONF_VIDEO_PRIMITIVE_GRAPHICS
EXTERN _bc_video_draw_surface_state
ENDIF

; Return the native writer for the draw mode, operation and clipping policy.
;
; if (op > XOR || mode >= 5 || !mode_table[mode]) return NULL;
; return mode_table[mode][(in_bounds ? 0 : 3) + op];
;
; B=operation, A=in_bounds (any nonzero). Return HL=writer, Z if NULL.
; Preserve IX/IY, clobber AF/BC/DE/HL. Tables contain only the configured
; primitive modes.
bc__draw_select_regs:
IFDEF BASECONF_VIDEO_PRIMITIVE_GRAPHICS
        ld c,a
        ld a,b
        cp 3
        jr nc,@none
        ld a,c
        or a
        ld a,b
        jr nz,@index
        add a,3
@index:
        add a,a
        ld c,a                       ; byte offset of the two-byte writer

        ld a,(_bc_video_draw_surface_state)
        cp 5                         ; first hardware-text mode
        jr nc,@none
        add a,a
        ld e,a
        ld d,0
        ld hl,bc_draw_mode_tables
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
IFNDEF BASECONF_VIDEO_PRIMITIVE_ALL
        ld a,d
        or e
        jr z,@none
ENDIF
        ex de,hl
        ld b,0
        add hl,bc
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        or h
        ret
@none:
ENDIF
        xor a
        ld h,a
        ld l,a
        ret

IFDEF BASECONF_VIDEO_PRIMITIVE_GRAPHICS
SECTION rodata_graphics
; Indexed by bc_video_mode_t. Both ZX layouts use the same writer table.
bc_draw_mode_tables:
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_256
        defw bc_draw_zx_writers
ELSE
        defw 0
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_MULTICOLOR
        defw bc_draw_zx_writers
ELSE
        defw 0
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
        defw bc_draw_pentagon_writers
ELSE
        defw 0
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
        defw bc_draw_atm320_writers
ELSE
        defw 0
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
        defw bc_draw_atm640_writers
ELSE
        defw 0
ENDIF

IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_BITMAP
EXTERN _bc__draw_zx_set
EXTERN _bc__draw_zx_clear
EXTERN _bc__draw_zx_xor
EXTERN _bc__draw_zx_set_clipped
EXTERN _bc__draw_zx_clear_clipped
EXTERN _bc__draw_zx_xor_clipped
bc_draw_zx_writers:
        defw _bc__draw_zx_set, _bc__draw_zx_clear, _bc__draw_zx_xor
        defw _bc__draw_zx_set_clipped, _bc__draw_zx_clear_clipped, _bc__draw_zx_xor_clipped
ENDIF

IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
EXTERN _bc__draw_pentagon_set
EXTERN _bc__draw_pentagon_clear
EXTERN _bc__draw_pentagon_xor
EXTERN _bc__draw_pentagon_set_clipped
EXTERN _bc__draw_pentagon_clear_clipped
EXTERN _bc__draw_pentagon_xor_clipped
bc_draw_pentagon_writers:
        defw _bc__draw_pentagon_set, _bc__draw_pentagon_clear, _bc__draw_pentagon_xor
        defw _bc__draw_pentagon_set_clipped, _bc__draw_pentagon_clear_clipped, _bc__draw_pentagon_xor_clipped
ENDIF

IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
EXTERN _bc__draw_atm320_set
EXTERN _bc__draw_atm320_clear
EXTERN _bc__draw_atm320_xor
EXTERN _bc__draw_atm320_set_clipped
EXTERN _bc__draw_atm320_clear_clipped
EXTERN _bc__draw_atm320_xor_clipped
bc_draw_atm320_writers:
        defw _bc__draw_atm320_set, _bc__draw_atm320_clear, _bc__draw_atm320_xor
        defw _bc__draw_atm320_set_clipped, _bc__draw_atm320_clear_clipped, _bc__draw_atm320_xor_clipped
ENDIF

IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
EXTERN _bc__draw_atm640_set
EXTERN _bc__draw_atm640_clear
EXTERN _bc__draw_atm640_xor
EXTERN _bc__draw_atm640_set_clipped
EXTERN _bc__draw_atm640_clear_clipped
EXTERN _bc__draw_atm640_xor_clipped
bc_draw_atm640_writers:
        defw _bc__draw_atm640_set, _bc__draw_atm640_clear, _bc__draw_atm640_xor
        defw _bc__draw_atm640_set_clipped, _bc__draw_atm640_clear_clipped, _bc__draw_atm640_xor_clipped
ENDIF
ENDIF
