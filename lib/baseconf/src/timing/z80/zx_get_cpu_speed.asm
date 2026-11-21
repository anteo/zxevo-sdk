        MODULE zx_get_cpu_speed
SECTION code_clib
PUBLIC _zx_get_cpu_speed
INCLUDE "memory/readback.inc"

; Read the CPU speed selector from the system and EFF7 readback bytes.
;
; if (!speed) return ZX_INVALID_ARGUMENT;
; sys = readback(0x0c); eff7 = readback(0x0b);
; *speed = (sys & 8) ? ZX_CPU_14_MHZ
;                    : (eff7 & 0x10) ? ZX_CPU_3_5_MHZ : ZX_CPU_7_MHZ;
; return ZX_OK;
;
; Fastcall output pointer in HL, status in L. H holds the system byte across
; EFF7 readback. Preserve IX/IY, clobber AF/BC/DE/HL.
_zx_get_cpu_speed:
        ex de,hl
        ld a,d
        or e
        jr z,@invalid
        BC_MEM_READBACK 0Ch, h
        BC_MEM_READBACK 0Bh, l
        bit 3,h
        ld a,2                       ; ZX_CPU_14_MHZ
        jr nz,@store
        bit 4,l
        ld a,0                       ; ZX_CPU_3_5_MHZ
        jr nz,@store
        inc a                        ; ZX_CPU_7_MHZ
@store:
        ld (de),a
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
