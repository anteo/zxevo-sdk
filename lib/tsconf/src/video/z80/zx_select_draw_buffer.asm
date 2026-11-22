        MODULE zx_select_draw_buffer
INCLUDE "video/draw_buffer.inc"
SECTION code_clib
PUBLIC _zx_select_draw_buffer
EXTERN _ts__video_commit_draw_buffer
EXTERN _ts_video_prepared_buffers
EXTERN _ts__memory_window_owner
EXTERN ts__graphics_group_depth

; Activate a prepared buffer using its stored format, page and CPU base.
;
; if (slot >= 2) return ZX_INVALID_ARGUMENT;
; buffer = &prepared[slot];
; if (buffer->config == 0xff) return ZX_UNAVAILABLE;
; if (graphics_depth || window_owner) return ZX_BUSY;
; return commit_draw_buffer(buffer);
;
; SDCC fastcall L=slot, L=status. Preserve IX/IY, clobber AF/BC/DE/HL.
_zx_select_draw_buffer:
        ld a,l
        cp 2
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret nc
        ld hl,_ts_video_prepared_buffers
        or a
        jr z,@slot
        ld hl,_ts_video_prepared_buffers+TS_DRAW_SLOT_SIZE
@slot:
        ld a,(hl)
        cp 0ffh
        jr z,@unavailable
        ld a,(ts__graphics_group_depth)
        or a
        jr nz,@busy
        ld de,(_ts__memory_window_owner)
        ld a,d
        or e
        jr nz,@busy
        jp _ts__video_commit_draw_buffer
@unavailable:
        ld l,3                       ; ZX_UNAVAILABLE
        ret
@busy:
        ld l,2                       ; ZX_BUSY
        ret
