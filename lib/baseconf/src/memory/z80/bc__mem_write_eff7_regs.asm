        MODULE bc__mem_write_eff7_regs
INCLUDE "memory/readback.inc"
SECTION code_clib
PUBLIC bc__mem_write_eff7_regs

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
bc__mem_write_eff7_regs:
        BC_MEM_READBACK 0Ch, l
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
        BC_MEM_READBACK 0Bh, a
        cp e
        ld l,6                       ; ZX_UNSAFE_CONTEXT
        ret nz
        ld l,0                       ; ZX_OK
        ret
