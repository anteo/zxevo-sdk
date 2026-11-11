        MODULE ts_video_select_draw_surface
SECTION code_clib
PUBLIC _ts_video_select_draw_surface
PUBLIC ts_select_surface
EXTERN ts_console_set_geometry
EXTERN ts_draw_config
EXTERN ts_draw_base
EXTERN ts__graphics_group_depth

; Copy a validated draw surface. Leave the previous target on error.
;
; if (!surface) return INVALID_ARGUMENT;
; if (graphics_group) return BUSY;
; if (!enabled_mode(surface)) return UNSUPPORTED;
; if (!valid_location(surface)) return INVALID_ARGUMENT;
; draw_config = surface->config & 0xc3;
; draw_page = surface->page;
; draw_base = high_byte(surface->base);
; if (layout_changed) update_console_geometry();
; return OK;
;
; Fastcall HL=descriptor (config:8, physical page:8, base:16).
; Internal entry A=config and HL=address of page and base. L=status.
; Caller owns the mappings. Clobber AF/BC/DE/HL. Preserve IX/IY.
_ts_video_select_draw_surface:
        ld a,h
        or l
        jr z,invalid_surface
        ld a,(hl)
        inc hl
ts_select_surface:
        push af
        ld a,(ts__graphics_group_depth)
        or a
        jr z,@no_group
        pop af
        ld l,2                       ; ZX_BUSY
        ret
@no_group:
        pop af
        and 0c3h
        ld c,a
        ld b,(hl)
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        and 3
IFNDEF TSCONF_VIDEO_ALL
IFNDEF TSCONF_VIDEO_ZX
        jr z,unsupported_mode
ENDIF
IFNDEF TSCONF_VIDEO_16C
        cp 1
        jr z,unsupported_mode
ENDIF
IFNDEF TSCONF_VIDEO_256C
        cp 2
        jr z,unsupported_mode
ENDIF
IFNDEF TSCONF_VIDEO_TEXT
        cp 3
        jr z,unsupported_mode
ENDIF
        or a
ENDIF
        jr z,@mapped
        cp 3
        jr z,@mapped
        dec a
        ld a,07h                   ; 16c occupies eight pages
        jr z,@packed
        ld a,0fh                   ; 256c occupies 16 pages
@packed:
        and b
        jr nz,invalid_surface
        jr @store
@mapped:
        ld a,d
        and 3fh
        or e
        jr nz,invalid_surface
@store:
        ld a,(ts_draw_config)
        cp c
        ld (ts_draw_config),bc
        ld a,d
        ld (ts_draw_base),a
        call nz,ts_console_set_geometry
        ld l,0                       ; ZX_OK
        ret
invalid_surface:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
IFNDEF TSCONF_VIDEO_ALL
unsupported_mode:
        ld l,5                       ; ZX_UNSUPPORTED
        ret
ENDIF

