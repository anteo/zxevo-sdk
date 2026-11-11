        MODULE bc__storage_fdd_system_port
SECTION code_clib
PUBLIC _bc__storage_fdd_system_port
EXTERN bc__video_system_port_for_regs

; Calculate xx77, setting its palette gate address bit if requested.
;
; if (force_palette_closed) config |= 0x80;
; return system_port_for(config, false);
;
; SDCC config at SP+2, force_palette_closed at SP+3, port in HL.
; Preserve E/IX/IY, clobber AF/BC/D/HL.
_bc__storage_fdd_system_port:
        ld hl,2
        add hl,sp
        ld d,(hl)
        inc hl
        ld a,(hl)
        or a
        ld a,d
        jr z,@port
        or 80h
@port:
        ld c,0
        jp bc__video_system_port_for_regs
