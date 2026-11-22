        MODULE zx_display_buffer
EXTERN _ts_video_prepared_buffers
EXTERN ts__video_display_page_e
SECTION code_clib
PUBLIC _zx_display_buffer

; Display the physical base page of a prepared buffer.
;
; if (slot >= 2) return ZX_INVALID_ARGUMENT;
; if (prepared[slot].config == 0xff) return ZX_UNAVAILABLE;
; return display_page(prepared[slot].page);
;
; SDCC fastcall L=slot, L=status. Same clobbers as zx_display_page.
_zx_display_buffer:
        ld a,l
        cp 2
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret nc
        ld hl,_ts_video_prepared_buffers
        or a
        jr z,@slot
        ld hl,_ts_video_prepared_buffers+3
@slot:
        ld a,(hl)
        cp 0ffh
        jr z,@empty
        inc hl
        ld e,(hl)                    ; physical base page
        jp ts__video_display_page_e
@empty:
        ld l,3                       ; ZX_UNAVAILABLE
        ret
