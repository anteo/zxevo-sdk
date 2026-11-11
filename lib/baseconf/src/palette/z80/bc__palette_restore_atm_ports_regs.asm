        MODULE bc__palette_restore_atm_ports_regs
SECTION code_clib
PUBLIC bc__palette_restore_atm_ports_regs
EXTERN bc__video_system_port_for_regs

; Restore the shared FDD register and the original xx77 address policy. Model:
;
; port = system_port_for(config, 0);
; data = config & 0x0f;
; OUT(port | 0x4000, data);
; OUT(0x00ff, fdd_control);
; OUT(port, data);
;
; E = saved config, D = saved FDD control. Caller owns the palette-write context.
; Preserve DE/IX/IY, clobber AF/BC/HL. HL retains the original port while
; the first write forces A14 high to close the strobe before the FDD write.
bc__palette_restore_atm_ports_regs:
        ld a,e
        ld c,0
        call bc__video_system_port_for_regs
        ld a,e
        and 0Fh
        ld b,h
        ld c,l
        set 6,b
        out (c),a                    ; close the palette strobe
        ld bc,00FFh
        out (c),d                    ; restore FDD while the strobe is closed
        ld b,h
        ld c,l
        out (c),a                    ; restore the saved A14 policy
        ret
