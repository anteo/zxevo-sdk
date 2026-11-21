        MODULE zx_select_draw_buffer
SECTION code_clib
PUBLIC _zx_select_draw_buffer
EXTERN _bc__video_publish_draw_buffer
EXTERN _bc_video_prepared_buffers
EXTERN _bc_video_draw_surface_state
EXTERN _bc_video_operation_depth
EXTERN _bc_video_cache_valid
EXTERN _bc_video_surface_selected
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base

; Activate a prepared buffer using its stored CPU mappings.
;
; if (slot >= 2) return ZX_INVALID_ARGUMENT;
; buffer = &prepared[slot];
; if (!buffer->window0_high) return ZX_UNAVAILABLE;
; if (video_depth) return ZX_BUSY;
; if (!surface_selected || !cache_valid || draw_surface.mode != buffer->mode)
;     return publish_draw_buffer(buffer);
; page0_base = buffer->window0_high << 8;
; page1_base = buffer->window1_high << 8;
; draw_surface.page0 = buffer->page0; draw_surface.page1 = buffer->page1;
; return ZX_OK;
;
; SDCC fastcall L=slot, L=status. Preserve IX/IY, clobber AF/BC/DE/HL.
; The two window bases are aligned; their low bytes are already zero.
_zx_select_draw_buffer:
        ld a,l
        cp 2
        ld l,1                        ; ZX_INVALID_ARGUMENT
        ret nc
        ld hl,_bc_video_prepared_buffers
        or a
        jr z,@slot
        ld hl,_bc_video_prepared_buffers+7
@slot:
        ld a,(hl)
        or a
        jr z,@unavailable
        ld a,(_bc_video_operation_depth)
        or a
        jr nz,@busy
        ld a,(_bc_video_surface_selected)
        or a
        jp z,_bc__video_publish_draw_buffer
        ld a,(_bc_video_cache_valid)
        or a
        jp z,_bc__video_publish_draw_buffer
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld a,(_bc_video_draw_surface_state)
        cp (hl)
        jr nz,@change_mode
        inc hl
        ld c,(hl)
        inc hl
        ld b,(hl)
        ld (_bc_video_draw_surface_state+1),bc
        ld a,e
        ld (_bc_video_page0_base+1),a
        ld a,d
        ld (_bc_video_page1_base+1),a
        ld l,0                        ; ZX_OK
        ret
@change_mode:
        dec hl
        dec hl
        jp _bc__video_publish_draw_buffer
@unavailable:
        ld l,3                        ; ZX_UNAVAILABLE
        ret
@busy:
        ld l,2                        ; ZX_BUSY
        ret
