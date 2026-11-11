        MODULE zx_graphics_get_size
SECTION code_clib
PUBLIC _zx_graphics_get_size
EXTERN _bc_mem_initialized
EXTERN _bc_video_draw_surface_state
EXTERN _bc__video_width
EXTERN _bc__video_height

; Report the selected bitmap dimensions without preparing a video lease.
;
; if (!size) return INVALID_ARGUMENT;
; if (!initialized) return NOT_INITIALIZED;
; if (mode >= ATM_TEXT_80) return UNSUPPORTED;
; *size = {video_width(), video_height()}; return OK;
;
; Fastcall HL=output, L=status. The dimension helpers preserve DE, which
; holds the width across the height call. AF/BC/DE/HL volatile, IX/IY preserved.
_zx_graphics_get_size:
        ld a,h
        or l
        jr z,@invalid
        ld a,(_bc_mem_initialized)
        or a
        jr z,@uninitialized
        ld a,(_bc_video_draw_surface_state)
        cp 5                         ; BC_VIDEO_ATM_TEXT_80
        jr nc,@unsupported
        push hl
        call _bc__video_width
        ex de,hl
        call _bc__video_height
        ex (sp),hl
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        pop de
        ld (hl),e
        inc hl
        ld (hl),d
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
@uninitialized:
        ld l,4                       ; ZX_NOT_INITIALIZED
        ret
@unsupported:
        ld l,5                       ; ZX_UNSUPPORTED
        ret
