        MODULE ts_video_get_raster_size
SECTION code_clib
PUBLIC _ts_video_get_raster_size
EXTERN ts_video_config
EXTERN ts__video_raster_cells

; Report the display's active pixel area from the saved VConfig and timing.
;
; if (!size) return INVALID_ARGUMENT;
; if (display_config == UNKNOWN) return NOT_INITIALIZED;
; (columns, rows) = raster_cells(display_config);
; *size = (8*columns, 8*rows); return OK;
;
; Fastcall HL=output struct (two 16-bit fields). Status in L.
; Save only the output pointer on the stack. AF/BC/DE/HL volatile,
; IX/IY preserved. No hardware readback.
_ts_video_get_raster_size:
        ld a,h
        or l
        jr z,@invalid
        ld a,(ts_video_config)
        cp 0ffh
        jr z,@unknown
        push hl
        call ts__video_raster_cells
        ld l,c
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        pop de
        ex de,hl
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        ex de,hl
        ld l,b
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ex de,hl
        ld (hl),e
        inc hl
        ld (hl),d
        ld l,0
        ret
@invalid:
        ld l,1
        ret
@unknown:
        ld l,4
        ret
