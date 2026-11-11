        MODULE zx_set_cpu_speed
SECTION code_clib
PUBLIC _zx_set_cpu_speed
EXTERN bc__mem_readback_register_regs
EXTERN bc__mem_write_eff7_regs
EXTERN bc__video_system_port_for_regs
EXTERN _bc__mem_shadow_scope_begin
EXTERN bc__mem_shadow_scope_end_regs

; Select the CPU clock while preserving the video mode, address decoding and
; unrelated EFF7 bits. Confirm each written clock bit through readback.
;
; if (speed > ZX_CPU_14_MHZ) return ZX_INVALID_ARGUMENT;
; if (speed != ZX_CPU_14_MHZ) {
;     eff7 = (readback(0x0b) & ~0x10) | (speed == ZX_CPU_3_5_MHZ ? 0x10 : 0);
;     status = write_eff7(eff7);
;     if (status != ZX_OK) return status;
; }
; sys = readback(0x0c);
; value = (sys & 7) | (speed == ZX_CPU_14_MHZ ? 8 : 0);
; port = system_port_for(sys, 0);
; bf = shadow_scope_begin();
; OUT(port, value);
; shadow_scope_end(bf);
; return ((readback(0x0c) ^ value) & 8) ? ZX_UNSAFE_CONTEXT : ZX_OK;
;
; Fastcall speed byte in L, status in L. Preserve IX/IY, clobber
; AF/BC/DE/HL. Caller serializes access to EFF7, xx77 and BF. E holds the
; requested speed and is saved across the EFF7 write, which verifies D4 and
; rejects DOS. The final xx77 write only changes the other clock selector.
_zx_set_cpu_speed:
        ld a,l
        cp 3
        jr nc,@invalid
        ld e,a
        cp 2
        jr z,@system

        ld b,0Bh
        call bc__mem_readback_register_regs
        res 4,l
        bit 0,e
        jr nz,@write_eff7
        set 4,l
@write_eff7:
        push de
        ld e,l
        call bc__mem_write_eff7_regs
        pop de
        ld a,l
        or a
        ret nz

@system:
        ld b,0Ch
        call bc__mem_readback_register_regs
        ld a,l
        and 7
        bit 1,e
        jr z,@port
        or 8
@port:
        ld d,a                       ; xx77 data, including the current video mode
        ld a,l                       ; 0Ch also carries the address bits A8/A9/A14
        ld c,0
        call bc__video_system_port_for_regs
        ld e,l                       ; preserve low port byte while L receives BF
        call _bc__mem_shadow_scope_begin
        ld a,l
        ld b,h
        ld c,e
        out (c),d
        call bc__mem_shadow_scope_end_regs

        ld b,0Ch
        call bc__mem_readback_register_regs
        ld a,l
        xor d
        and 8
        ld l,6                       ; ZX_UNSAFE_CONTEXT
        ret nz
        ld l,a                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
