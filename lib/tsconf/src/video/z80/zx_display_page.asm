        MODULE zx_display_page
SECTION code_clib
PUBLIC _zx_display_page
EXTERN _ts__video_set_page
EXTERN ts_video_config
EXTERN ts__graphics_group_depth

; Display a page aligned to the current layout, without changing draw state.
;
; if (graphics_group) return ZX_BUSY;
; if (config == UNKNOWN) return ZX_NOT_INITIALIZED;
; if ((page & alignment_mask[config & 3]) != 0) return ZX_INVALID_ARGUMENT;
; write_page(page); return ZX_OK;
;
; SDCC page byte at SP+2, L=status. AF/BC/DE/HL volatile, IX/IY preserved.
_zx_display_page:
        ld hl,2
        add hl,sp
        ld e,(hl)
        ld a,(ts__graphics_group_depth)
        or a
        ld l,2                       ; ZX_BUSY
        ret nz
        ld a,(ts_video_config)
        cp 0ffh
        ld l,4                       ; ZX_NOT_INITIALIZED
        ret z
        and 3
        dec a
        jr z,@packed16
        dec a
        jr nz,@show
        ld a,0fh
        jr @check
@packed16:
        ld a,07h
@check:
        and e
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret nz
@show:
        ld l,e
        call _ts__video_set_page
        ld l,0                       ; ZX_OK
        ret
