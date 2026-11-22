        MODULE bc__video_invalidate_draw_cache
EXTERN _bc_video_bound_slots
EXTERN _bc_video_cache_valid
EXTERN _bc_video_cpu_base
EXTERN _bc_video_mapped_page
SECTION code_clib
PUBLIC _bc__video_invalidate_draw_cache

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
