        MODULE display
SECTION code_clib
PUBLIC _zx_display_page
PUBLIC _zx_display_buffer
EXTERN _ts_video_prepared_buffers
EXTERN ts_video_config
EXTERN ts__graphics_group_depth

; Display the physical base page of a prepared buffer.
;
; if (slot >= 2) return ZX_INVALID_ARGUMENT;
; if (prepared[slot].config == 0xff) return ZX_UNAVAILABLE;
; return display_page(prepared[slot].page);
;
; SDCC fastcall L=slot, L=status. Same clobbers as zx_display_page.
_zx_display_buffer:
        ld a,l
        cp 2
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret nc
        ld hl,_ts_video_prepared_buffers
        or a
        jr z,@slot
        ld hl,_ts_video_prepared_buffers+3
@slot:
        ld a,(hl)
        cp 0ffh
        jr z,@empty
        inc hl
        ld e,(hl)                    ; physical base page
        jr display_page
@empty:
        ld l,3                       ; ZX_UNAVAILABLE
        ret

; Display a page aligned to the current layout, without changing draw state.
;
; if (graphics_group) return ZX_BUSY;
; if (config == UNKNOWN) return ZX_NOT_INITIALIZED;
; if ((page & alignment_mask[config & 3]) != 0) return ZX_INVALID_ARGUMENT;
; write_page(page); return ZX_OK;
;
; SDCC page byte at SP+2 or E at the shared entry. L=status.
; AF/BC/DE/HL volatile, IX/IY preserved.
_zx_display_page:
        ld hl,2
        add hl,sp
        ld e,(hl)
display_page:
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
