        MODULE zx_display_surface
SECTION code_clib
PUBLIC _zx_display_surface
EXTERN _zx_set_video_mode
EXTERN _ts__video_set_page

; Show a physical surface using its display configuration and page.
;
; if (!surface || surface->page1 || !aligned(surface->page0, surface->mode))
;     return INVALID_ARGUMENT;
; status = set_video_mode(surface->mode);
; if (status != OK) return status;
; write_page(surface->page0); return OK;
;
; SDCC surface pointer at SP+2. L=status. AF/BC/DE/HL volatile, IX/IY preserved.
; Save the page on the stack across the SDCC caller-clean mode argument.
_zx_display_surface:
        ld hl,2
        add hl,sp
        ld e,(hl)
        inc hl
        ld h,(hl)
        ld l,e
        ld a,h
        or l
        jr z,@invalid
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld c,(hl)
        inc hl
        ld a,(hl)
        or a
        jr nz,@invalid               ; TSConf surfaces have no second page

        ld a,e
        and 3
        dec a
        jr z,@packed16
        dec a
        jr nz,@show
        ld a,0fh
        jr @align
@packed16:
        ld a,07h
@align:
        and c
        jr nz,@invalid
@show:
        push bc
        push de
        call _zx_set_video_mode
        pop de
        pop bc
        ld a,l
        or a
        ret nz
        ld l,c
        call _ts__video_set_page
        ld l,0
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
