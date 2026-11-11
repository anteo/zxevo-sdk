        MODULE bc__video_system_port_for_regs
SECTION code_clib
PUBLIC bc__video_system_port_for_regs

; Derive the system-port address from a readback configuration byte. Model:
;
; high = 0x3c | ((config >> 5) & 3);
; if (!palette_allowed) high |= (config & 0x80) >> 1;
; return (high << 8) | 0x77;
;
; A = config, C = palette_allowed (zero or nonzero), HL = port.
; Config bits 5/6 select A8/A9, and bit 7 supplies A14 unless palette access
; is allowed. Preserve C/DE/IX/IY, clobber AF/B/HL. No port access.
bc__video_system_port_for_regs:
        ld b,a
        rlca
        rlca
        rlca                         ; config bits 5/6 -> high-byte bits 0/1
        and 3
        or 3Ch
        ld h,a
        ld l,77h
        bit 7,b
        ret z
        ld a,c
        or a
        ret nz
        set 6,h                      ; A14
        ret
