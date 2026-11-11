        MODULE ts__video_raster_cells
SECTION code_clib
PUBLIC ts__video_raster_cells

; Decode the raster in eight-pixel units for the display and console APIs.
;
; (columns, rows) = raster_geometry[config >> 6];
; if ((config & 3) == TEXT) columns *= 2;
; The table uses 30 rows for the largest raster in 60 Hz builds.
;
; A=VConfig. Return C=columns, B=rows. AF/DE/HL volatile, IX/IY preserved.
ts__video_raster_cells:
        ld b,a
        rlca
        rlca
        and 3
        add a,a
        ld e,a
        ld d,0
        ld hl,raster_geometry
        add hl,de
        ld c,(hl)
        inc hl
        ld a,b
        and 3
        cp 3
        jr nz,@height
        sla c
@height:
        ld b,(hl)
        ret

SECTION rodata_clib
raster_geometry:
        defb 32,24, 40,25, 40,30
IFDEF TSCONF_VIDEO_60HZ
        defb 45,30
ELSE
        defb 45,36
ENDIF
