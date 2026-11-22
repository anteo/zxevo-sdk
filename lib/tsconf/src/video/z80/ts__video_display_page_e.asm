        MODULE ts__video_display_page_e
EXTERN ts__graphics_group_depth
EXTERN ts_video_config
SECTION code_clib
PUBLIC ts__video_display_page_e

; Display a page aligned to the current layout, without changing draw state.
;
; if (graphics_group) return ZX_BUSY;
; if (config == UNKNOWN) return ZX_NOT_INITIALIZED;
; if ((page & alignment_mask[config & 3]) != 0) return ZX_INVALID_ARGUMENT;
; write_page(page); return ZX_OK;
;
; SDCC page byte at SP+2 or E at the shared entry. L=status.
; AF/BC/DE/HL volatile, IX/IY preserved.
ts__video_display_page_e:
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
        ld bc,01afh
        out (c),e
        ld l,0                       ; ZX_OK
        ret
