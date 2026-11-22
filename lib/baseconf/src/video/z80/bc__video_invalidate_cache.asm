        MODULE bc__video_invalidate_cache
INCLUDE "video/draw_buffer.inc"
EXTERN _bc__video_invalidate_draw_cache
EXTERN _bc_video_prepared_buffers
SECTION code_clib
PUBLIC _bc__video_invalidate_cache

; Invalidate the video selector and both prepared buffers after a paging change.
; SDCC void/no arguments. Preserve BC/DE/IX/IY; clobber AF/HL. Independent of
; the C synchronizer so callers needing only invalidation don't link it.
_bc__video_invalidate_cache:
        xor a
        ld (_bc_video_prepared_buffers),a     ; first window0_high
        ld (_bc_video_prepared_buffers+BC_DRAW_SLOT_SIZE),a  ; second window0_high
        jp _bc__video_invalidate_draw_cache
