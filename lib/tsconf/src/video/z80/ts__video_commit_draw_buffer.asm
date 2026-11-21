        MODULE ts__video_commit_draw_buffer
SECTION code_clib
PUBLIC _ts__video_commit_draw_buffer
EXTERN ts_console_set_geometry
EXTERN ts_draw_config
EXTERN ts_draw_base

; Publish a validated draw buffer and refresh console geometry if its format changes.
;
; config = buffer->config & 0xc3;
; layout_changed = draw_config != config;
; draw_config = config;
; draw_page = buffer->page;
; draw_base = buffer->window_high;
; if (layout_changed) update_console_geometry();
; return ZX_OK;
;
; Fastcall HL = buffer (config, page, high byte of the CPU window). The caller
; has validated the format and location and completed any required mapping.
; Clobber AF/BC/DE/HL, preserve IX/IY. L=status.
_ts__video_commit_draw_buffer:
        ld a,(hl)
        and 0c3h
        ld c,a
        inc hl
        ld b,(hl)
        inc hl
        ld e,(hl)
        ld a,(ts_draw_config)
        cp c
        ld (ts_draw_config),bc
        ld a,e
        ld (ts_draw_base),a
        call nz,ts_console_set_geometry
        ld l,0                       ; ZX_OK
        ret
