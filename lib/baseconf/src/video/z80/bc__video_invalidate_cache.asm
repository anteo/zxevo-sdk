        MODULE bc__video_invalidate_cache
INCLUDE "video/draw_buffer.inc"
SECTION code_clib
PUBLIC _bc__video_invalidate_cache
PUBLIC _bc__video_invalidate_draw_cache
EXTERN _bc_video_bound_slots
EXTERN _bc_video_cache_valid
EXTERN _bc_video_cpu_base
EXTERN _bc_video_mapped_page
EXTERN _bc_video_prepared_buffers

; Invalidate the video selector and both prepared buffers after a paging change.
; SDCC void/no arguments. Preserve BC/DE/IX/IY; clobber AF/HL. Independent of
; the C synchronizer so callers needing only invalidation don't link it.
_bc__video_invalidate_cache:
        xor a
        ld (_bc_video_prepared_buffers),a     ; first window0_high
        ld (_bc_video_prepared_buffers+BC_DRAW_SLOT_SIZE),a  ; second window0_high

; Invalidate only the active draw cache. The caller owns slot invalidation.
; Same ABI and clobbers as the entry above.
_bc__video_invalidate_draw_cache:
        xor a
        ld (_bc_video_bound_slots),a
        ld (_bc_video_cache_valid),a
        ld hl,0
        ld (_bc_video_cpu_base),hl
        dec a
        ld (_bc_video_mapped_page),a
        ret
