        MODULE bc__video_end
SECTION code_clib
PUBLIC _bc__video_end
PUBLIC _zx_graphics_end
EXTERN _bc_video_operation_depth
EXTERN _bc_video_mapped_page
EXTERN _bc_video_cpu_base

; Close one level of a prepared video operation. Model:
;
; if (!depth) return NOT_INITIALIZED;
; if (--depth == 0) { mapped_page = 0xff; cpu_base = 0; }
; return OK;
;
; SDCC no arguments; status in L, flags unspecified. Preserve BC/DE/IX/IY;
; clobber AF/HL. The last end clears the current selector, keeping cached
; surface bases for the next begin. No stack locals or port writes.
_zx_graphics_end:
_bc__video_end:
        ld a,(_bc_video_operation_depth)
        or a
        ld l,4                       ; ZX_NOT_INITIALIZED
        ret z
        dec a
        ld (_bc_video_operation_depth),a
        ld l,0                       ; ZX_OK
        ret nz
        dec a                        ; zero depth -> invalid page sentinel FFh
        ld (_bc_video_mapped_page),a
        ld hl,0
        ld (_bc_video_cpu_base),hl
        ret
