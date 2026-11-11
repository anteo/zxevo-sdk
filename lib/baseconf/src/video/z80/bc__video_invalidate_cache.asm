        MODULE bc__video_invalidate_cache
SECTION code_clib
PUBLIC _bc__video_invalidate_cache
EXTERN _bc_video_cache_valid
EXTERN _bc_video_cpu_base
EXTERN _bc_video_mapped_page

; Invalidate the cached video selector; the next outer begin resynchronizes.
; SDCC void/no arguments. Preserve BC/DE/IX/IY; clobber AF/HL. Independent of
; the C synchronizer so callers needing only invalidation don't link it.
_bc__video_invalidate_cache:
        xor a
        ld (_bc_video_cache_valid),a
        ld hl,0
        ld (_bc_video_cpu_base),hl
        dec a
        ld (_bc_video_mapped_page),a
        ret
