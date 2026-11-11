        MODULE zx_wait_frames

SECTION code_clib
PUBLIC _zx_wait_frames
EXTERN _zx_wait_frame

; Wait for a fixed number of changes to the caller's frame counter.
;
; while (count--) { status = zx_wait_frame(counter); if (status) return status; }
; return ZX_OK;
;
; SDCC caller-clean: counter at SP+2, count at SP+4. BC holds the remaining
; count across zx_wait_frame, and one stack word preserves the counter.
; Return status in L. AF/BC/DE/HL volatile, IX/IY and the INT state preserved.
_zx_wait_frames:
        ld hl,2
        add hl,sp
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld c,(hl)
        inc hl
        ld b,(hl)
        ex de,hl
        jr @check_count
@wait:
        push hl
        call _zx_wait_frame
        ld a,l
        pop hl
        or a
        jr nz,@error
        dec bc
@check_count:
        ld a,b
        or c
        jr nz,@wait
@error:
        ld l,a
        ret
