        MODULE bc_read_beam_color

SECTION code_clib
PUBLIC _bc_read_beam_color

; Read the beam color at the current raster position. Model:
;
; if (!color) return ZX_INVALID_ARGUMENT;
; *color = IN(0x0dbd);
; return ZX_OK;
;
; SDCC color:16 at SP+2. Return status in L. Preserve IX/IY,
; clobber AF/BC/DE/HL. A null pointer returns before reading the port.
_bc_read_beam_color:
        ld hl,2
        add hl,sp
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld a,d
        or e
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret z
        ld bc,0DBDh
        in a,(c)
        ld (de),a
        ld l,0                       ; ZX_OK
        ret
