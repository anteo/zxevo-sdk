        MODULE bc_set_shadow_ports_override
SECTION code_clib
PUBLIC _bc_set_shadow_ports_override
EXTERN _bc_video_operation_depth
EXTERN _bc__mem_write_shadow_override
EXTERN _bc__video_invalidate_cache

; Set BF.0 to the requested boolean and invalidate the video cache.
;
; if (video_operation_depth) return ZX_BUSY;
; write_shadow_override(enabled != 0);
; invalidate_video_cache();
; return ZX_OK;
;
; SDCC enabled byte at SP+2, status in L. Preserve DE/IX/IY,
; clobber AF/BC/HL.
_bc_set_shadow_ports_override:
        ld a,(_bc_video_operation_depth)
        or a
        ld l,2                       ; ZX_BUSY
        ret nz
        ld hl,2
        add hl,sp
        xor a
        cp (hl)
        sbc a,a
        and 1                        ; normalize any nonzero byte to 1
        ld l,a
        call _bc__mem_write_shadow_override
        call _bc__video_invalidate_cache
        ld l,0                       ; ZX_OK
        ret
