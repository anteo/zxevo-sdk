        MODULE bc__graphics_begin
SECTION code_graphics
PUBLIC _bc__graphics_begin
EXTERN _zx_graphics_begin
EXTERN _bc__video_width
EXTERN _bc__video_height
EXTERN _bc_graphics_width
EXTERN _bc_graphics_height

; Acquire a graphics lease and publish the dimensions used for clipping.
;
; if (graphics_begin() != ZX_OK) return 0;
; graphics_width = video_width(); graphics_height = video_height();
; return 1;
;
; SDCC no arguments. Return boolean in L, Z on failure. Preserve IX/IY,
; clobber AF/BC/DE/HL. Pair success with one video_end.
_bc__graphics_begin:
        call _zx_graphics_begin
        ld a,l
        or a
        jr nz,@failure
        call _bc__video_width
        ld (_bc_graphics_width),hl
        call _bc__video_height
        ld (_bc_graphics_height),hl
        ld l,1
        or l
        ret
@failure:
        xor a
        ld l,a
        ret
