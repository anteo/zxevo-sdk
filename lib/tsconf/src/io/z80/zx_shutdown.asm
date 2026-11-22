        MODULE zx_shutdown
INCLUDE "video/draw_buffer.inc"
SECTION code_clib
PUBLIC _zx_shutdown
EXTERN _ts__memory_window_owner
EXTERN ts__graphics_group_depth
EXTERN ts_draw_config
EXTERN _ts_video_prepared_buffers

; Discard the software draw target without changing VConfig or paging.
;
; if (window_owner || graphics_depth) return BUSY;
; draw_config = UNSELECTED;
; prepared[0].config = prepared[1].config = UNSELECTED;
; return OK;
;
; SDCC no arguments, L=status. Clobber AF/HL and preserve BC/DE/IX/IY.
_zx_shutdown:
        ld hl,(_ts__memory_window_owner)
        ld a,h
        or l
        jr nz,@busy
        ld a,(ts__graphics_group_depth)
        or a
        jr nz,@busy
        ld a,0ffh
        ld (ts_draw_config),a
        ld (_ts_video_prepared_buffers),a
        ld (_ts_video_prepared_buffers+TS_DRAW_SLOT_SIZE),a
        ld l,0                       ; ZX_OK
        ret
@busy:
        ld l,2                       ; ZX_BUSY
        ret
