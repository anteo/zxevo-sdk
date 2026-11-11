        MODULE bc__video_begin
SECTION code_clib
PUBLIC _bc__video_begin
EXTERN _bc_mem_initialized
EXTERN _bc_mem_active_window_lease
EXTERN _bc_mem_active_map
EXTERN _bc_video_operation_depth
EXTERN _bc_video_cache_valid
EXTERN _bc_video_cached_map
EXTERN _bc_video_cached_manager_enabled
EXTERN _bc_video_draw_surface_state
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base
EXTERN _bc_video_mapped_page
EXTERN _bc_video_cpu_base
EXTERN _bc__video_invalidate_cache
EXTERN _bc__video_sync_cache

; Open or nest a prepared video operation. Model:
;
; if (!initialized) return NOT_INITIALIZED;
; if (window_lease || depth == 255) return BUSY;
; if (depth) { ++depth; return OK; }
; if (cache_valid && map_changed) invalidate_cache();
; if (!cache_valid) {
;     status = sync_cache();
;     if (status != OK) return status;
; }
; if (!manager || !page0_base || !page1_base) return UNAVAILABLE;
; cpu_base = page0_base; mapped_page = page0; depth = 1; return OK;
;
; SDCC no arguments; status in L, flags unspecified. Preserve IX/IY; clobber
; AF/BC/DE/HL. No frame or outgoing arguments. Only the outermost operation
; reads the cache or invokes its C synchronizer; no hardware page remapping.
; Surface changes invalidate the cache when the new descriptor is published.
_bc__video_begin:
        ld a,(_bc_mem_initialized)
        or a
        ld l,4                       ; ZX_NOT_INITIALIZED
        ret z
        ld hl,(_bc_mem_active_window_lease)
        ld a,h
        or l
        ld l,2                       ; ZX_BUSY
        ret nz
        ld hl,_bc_video_operation_depth
        ld a,(hl)
        or a
        jr z,@outer
        inc a
        jr z,@busy                   ; depth 255 must not wrap to zero
        ld (hl),a
        ld l,0                       ; ZX_OK
        ret
@busy:
        ld l,2
        ret

@outer:
        ld a,(_bc_video_cache_valid)
        or a
        jr z,@sync
        ld a,(_bc_video_cached_map)
        ld hl,_bc_mem_active_map
        cp (hl)
        jr z,@check_pages
        call _bc__video_invalidate_cache
@sync:
        call _bc__video_sync_cache
        ld a,l
        or a
        ret nz                       ; failed sync may leave the old bases intact

@check_pages:
        ld a,(_bc_video_cached_manager_enabled)
        or a
        jr z,@unavailable
        ld hl,(_bc_video_page1_base)
        ld a,h
        or l
        jr z,@unavailable
        ld hl,(_bc_video_page0_base)
        ld a,h
        or l
        jr z,@unavailable
        ld (_bc_video_cpu_base),hl
        ld a,(_bc_video_draw_surface_state+1)
        ld (_bc_video_mapped_page),a
        ld a,1
        ld (_bc_video_operation_depth),a
        ld l,0                       ; ZX_OK
        ret
@unavailable:
        ld l,3                       ; ZX_UNAVAILABLE
        ret
