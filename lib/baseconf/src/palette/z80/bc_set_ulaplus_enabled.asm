        MODULE bc_set_ulaplus_enabled

SECTION code_clib
PUBLIC _bc_set_ulaplus_enabled

; Select the ULAplus mode register and write the supplied byte. Model:
;
; OUT(0xbf3b, 0x40);
; OUT(0xff3b, enabled);
;
; SDCC enabled:8 at SP+2, void result. Caller supplies 0 or 1.
; Preserve DE/IX/IY, clobber AF/BC/HL. Send enabled unchanged.
_bc_set_ulaplus_enabled:
        ld bc,0BF3Bh
        ld a,40h
        out (c),a
        ld hl,2
        add hl,sp
        ld a,(hl)
        ld b,0FFh                    ; BF3Bh selector -> FF3Bh data
        out (c),a
        ret
