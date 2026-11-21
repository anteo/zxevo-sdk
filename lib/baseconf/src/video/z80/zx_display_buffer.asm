        MODULE zx_display_buffer
SECTION code_clib
PUBLIC _zx_display_buffer
EXTERN _bc_video_prepared_buffers
EXTERN _bc_video_operation_depth
INCLUDE "memory/readback.inc"

; Present a prepared screen while preserving the live paging bits of 7FFD.
;
; if (slot >= 2) return ZX_INVALID_ARGUMENT;
; buffer = &prepared[slot];
; if (!buffer->window0_high) return ZX_UNAVAILABLE;
; if (video_depth) return ZX_BUSY;
; if (buffer->display_status != ZX_OK) return buffer->display_status;
; paging = readback(0x0a);
; if (((paging ^ buffer->display_flags) & 8) == 0) return ZX_OK;
; if ((paging & 0x20) && (buffer->display_flags & 4)) return ZX_BUSY;
; out(0x7ffd, paging ^ 8);
; return ZX_OK;
;
; SDCC fastcall L=slot, L=status. Preserve IX/IY, clobber AF/BC/DE/HL.
_zx_display_buffer:
        ld a,l
        cp 2
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret nc
        ld hl,_bc_video_prepared_buffers
        or a
        jr z,@slot
        ld hl,_bc_video_prepared_buffers+7
@slot:
        ld a,(hl)
        or a
        jr z,@empty
        ld a,(_bc_video_operation_depth)
        or a
        jr nz,@busy
        ld de,5                      ; display_status within the record
        add hl,de
        ld a,(hl)
        or a
        jr nz,@result
        inc hl
        ld e,(hl)                    ; desired screen and cached 128K mode flag
        BC_MEM_READBACK 0Ah, l
        ld a,l
        xor e
        and 8
        jr z,@result
        bit 5,l
        jr z,@flip
        bit 2,e
        jr nz,@busy
@flip:
        ld a,l
        xor 8                        ; screen differs, so only bit 3 changes
        ld bc,7ffdh
        out (c),a
        xor a
@result:
        ld l,a
        ret
@empty:
        ld l,3                       ; ZX_UNAVAILABLE
        ret
@busy:
        ld l,2                       ; ZX_BUSY
        ret
