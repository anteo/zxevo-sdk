        MODULE bc_read_font_row

SECTION code_clib
PUBLIC _bc_read_font_row
INCLUDE "memory/readback.inc"

; Read the glyph-row byte exposed at the current raster position. Model:
;
; if (!row) return ZX_INVALID_ARGUMENT;
; *row = readback(0x0e);
; return ZX_OK;
;
; SDCC row:16 at SP+2. Return status in L. Preserve IX/IY,
; clobber AF/BC/DE/HL. A null pointer returns before reading the port.
_bc_read_font_row:
        ld hl,2
        add hl,sp
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld a,d
        or e
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret z
        BC_MEM_READBACK 0Eh, a
        ld (de),a
        ld l,0                       ; ZX_OK
        ret
