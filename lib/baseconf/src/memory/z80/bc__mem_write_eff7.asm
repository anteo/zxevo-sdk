        MODULE bc__mem_write_eff7
SECTION code_clib
PUBLIC _bc__mem_write_eff7
PUBLIC bc__mem_write_eff7_regs
EXTERN bc__mem_readback_register_regs

; Write EFF7 through ordinary port decoding and confirm the stored value.
;
; if (readback(0x0c) & 0x10) return ZX_UNSAFE_CONTEXT;
; bf = in(0x00bf);
; if (bf & 1) out(0x00bf, bf & ~1);
; out(0xeff7, data);
; if (bf & 1) out(0x00bf, bf);
; return readback(0x0b) == data ? ZX_OK : ZX_UNSAFE_CONTEXT;
;
; SDCC data byte at SP+2 or register input E. Status in L. DOS keeps shadow
; decoding open regardless of BF.0. Preserve IX/IY, clobber AF/BC/DE/HL.
_bc__mem_write_eff7:
        ld hl,2
        add hl,sp
        ld e,(hl)
bc__mem_write_eff7_regs:
        ld b,0Ch
        call bc__mem_readback_register_regs
        bit 4,l
        ld l,6                       ; ZX_UNSAFE_CONTEXT
        ret nz
        ld bc,00BFh
        in d,(c)
        bit 0,d
        jr z,@write
        ld a,d
        and 0FEh
        out (c),a
@write:
        ld bc,0EFF7h
        out (c),e
        bit 0,d
        jr z,@verify
        ld bc,00BFh
        out (c),d
@verify:
        ld b,0Bh
        call bc__mem_readback_register_regs
        ld a,l
        cp e
        ld l,6                       ; ZX_UNSAFE_CONTEXT
        ret nz
        ld l,0                       ; ZX_OK
        ret
