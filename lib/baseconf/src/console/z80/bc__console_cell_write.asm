        MODULE bc__console_cell_write

SECTION code_clib
PUBLIC _bc__console_cell_write
IFDEF BASECONF_VIDEO_TEXT_HARDWARE
EXTERN _bc__text_cell_write
EXTERN _zx__console_text_bg
ENDIF
EXTERN _bc__console_graphics_cell_write

; SDCC caller-clean ABI: mode:8 at SP+2, surface:24 at SP+3,
; x:8 at SP+6, y:8 at SP+7, character:8 at SP+8. Preserve IX/IY.
;
; Writes one character to the selected console cell using the hardware text
; or bitmap font backend.
;
; Model:
;
; if (mode == ATM_TEXT_80 || mode == EVO_TEXT_80) text_cell_write(mode,surface,x,y,c);
; else graphics_cell_write(x,y,c);
;
; Caller holds the video lease and supplies in-range cells. AF/BC/DE/HL
; volatile; IX/IY preserved. The graphics call gets three fresh outgoing bytes;
; the text tail call reuses the original packed arguments.
_bc__console_cell_write:
IFDEF BASECONF_VIDEO_TEXT_HARDWARE
        ld hl,2
        add hl,sp
        ld a,(hl)
        sub 5                        ; ATM_TEXT_80=5, EVO_TEXT_80=6
        cp 2
        jr nc,@bitmap
        ld a,(_zx__console_text_bg)
        or a
        ret nz                       ; the CRT hook has no status result
        jp _bc__text_cell_write      ; identical arguments, no repacking
@bitmap:
ENDIF
        ld hl,6
        add hl,sp
        ld c,(hl)
        inc hl
        ld b,(hl)
        inc hl
        ld a,(hl)
        push af
        inc sp                       ; character:8
        push bc                      ; column:8, row:8
        call _bc__console_graphics_cell_write
        pop bc
        inc sp
        ret
