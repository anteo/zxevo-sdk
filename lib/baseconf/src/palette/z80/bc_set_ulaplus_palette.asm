        MODULE bc_set_ulaplus_palette

SECTION code_clib
PUBLIC _bc_set_ulaplus_palette
EXTERN _bc_get_video_mode

; Write a ULAplus palette entry in a supported live video mode. Model:
;
; if (index >= 64) return ZX_INVALID_ARGUMENT;
; mode = get_video_mode();
; if (mode != ZX_256 && mode != ZX_MULTICOLOR) return ZX_UNAVAILABLE;
; OUT(0xbf3b, index);
; OUT(0xff3b, color);
; return ZX_OK;
;
; SDCC index:8 at SP+2, color:8 at SP+3. Return status in L. Preserve IX/IY,
; clobber AF/BC/DE/HL. Reload the original arguments after the mode readback.
_bc_set_ulaplus_palette:
        ld hl,2
        add hl,sp
        ld a,(hl)
        cp 64
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret nc
        call _bc_get_video_mode
        ld a,l
        cp 2                         ; ZX_256 = 0, ZX_MULTICOLOR = 1
        ld l,3                       ; ZX_UNAVAILABLE
        ret nc
        ld hl,2
        add hl,sp
        ld bc,0BF3Bh
        ld a,(hl)
        out (c),a
        inc hl
        ld a,(hl)
        ld b,0FFh                    ; BF3Bh selector -> FF3Bh data
        out (c),a
        ld l,0                       ; ZX_OK
        ret
