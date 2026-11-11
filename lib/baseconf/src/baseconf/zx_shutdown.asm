        MODULE zx_shutdown
SECTION code_clib
PUBLIC _zx_shutdown
EXTERN _bc_mem_active_window_lease
EXTERN _bc_video_operation_depth
EXTERN _bc_mem_initialized
EXTERN _bc_video_surface_selected
EXTERN _bc__video_invalidate_cache

; Invalidate prepared paging and drawing state without changing hardware.
;
; if (window_lease || video_depth) return BUSY;
; mem_initialized = surface_selected = 0;
; invalidate_video_cache();
; return OK;
;
; SDCC no arguments, L=status. Clobber AF/HL and preserve BC/DE/IX/IY.
_zx_shutdown:
        ld hl,(_bc_mem_active_window_lease)
        ld a,h
        or l
        jr nz,@busy
        ld a,(_bc_video_operation_depth)
        or a
        jr nz,@busy
        ld (_bc_mem_initialized),a
        ld (_bc_video_surface_selected),a
        call _bc__video_invalidate_cache
        ld l,0                       ; ZX_OK
        ret
@busy:
        ld l,2                       ; ZX_BUSY
        ret
