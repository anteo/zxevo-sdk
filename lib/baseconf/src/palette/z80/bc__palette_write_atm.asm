        MODULE bc__palette_write_atm
SECTION code_clib
PUBLIC bc__palette_write_atm
EXTERN bc__mem_readback_register_regs
EXTERN _bc__mem_shadow_scope_open
EXTERN bc__mem_shadow_scope_end_regs
EXTERN bc__palette_fdd_control_from_status_regs
EXTERN bc__video_system_port_for_regs
EXTERN bc__palette_restore_atm_ports_regs

; Write one encoded color to the beam-selected ATM entry. Model:
;
; config = readback(0x0c);
; shadow_scope_open(bf);
; fdd_control = fdd_control_from_status(IN(0x00ff));
; open_port = system_port_for(config, 1);
; OUT(open_port, config & 0x0f);
; high = address_high ? address_high : open_port >> 8;
; OUT((high << 8) | 0xff, data);
; restore_palette_side_effects(config, fdd_control);
; shadow_scope_end(bf);
; return ZX_OK;
;
; A = saved BF, B = RGB444 address high byte or zero for RGB222, C = data.
; The caller checks BF.5 and times the write for the desired beam color.
; RGB444 always has address bits 2/3 set, so zero selects the RGB222 address
; unambiguously. Stack saves AF (BF) and BC (encoded write) in that order.
; Return ZX_OK in L. Preserve IX/IY, clobber AF/BC/DE/HL.
bc__palette_write_atm:
        ld d,a
        push af                      ; saved BF for the final shadow restore
        push bc                      ; encoded address/data
        ld b,0Ch
        call bc__mem_readback_register_regs
        ld e,l                       ; saved config, D still holds BF
        ld l,d
        bit 0,l
        call z,_bc__mem_shadow_scope_open
@shadow_ready:
        ld bc,00FFh
        in a,(c)
        call bc__palette_fdd_control_from_status_regs
        ld d,a                       ; saved FDD control
        ld a,e
        ld c,1
        call bc__video_system_port_for_regs
        ld b,h
        ld c,l
        ld a,e
        and 0Fh
        out (c),a                    ; open palette strobe

        pop bc
        ld a,b
        or a
        jr nz,@write
        ld b,h                       ; RGB222 reuses the open xx77 high byte
@write:
        ld a,c
        ld c,0FFh
        out (c),a
        call bc__palette_restore_atm_ports_regs
        pop af
        ld l,0                       ; ZX_OK
        jp bc__mem_shadow_scope_end_regs
