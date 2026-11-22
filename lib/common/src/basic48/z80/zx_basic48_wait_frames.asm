        MODULE zx_basic48_wait_frames
SECTION code_clib
PUBLIC _zx_basic48_wait_frames
EXTERN _zx_wait_frames

; Wait on BASIC's FRAMES low byte. Fastcall HL = frame count, status in L.
_zx_basic48_wait_frames:
        push hl
        ld hl,5C78h                  ; FRAMES
        push hl
        call _zx_wait_frames
        pop bc
        pop bc
        ret
