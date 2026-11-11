        MODULE bc__graphics_read_point
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC bc__graphics_read_point
EXTERN _bc__graphics_begin
EXTERN bc__graphics_pixel_regs
EXTERN _bc__video_end

; Read a clipped point as a pixel index or as a boolean under a lease.
;
; if (!graphics_begin()) return 0;
; value = inside(x,y) ? video_pixel(x,y,op,0) : 0;
; video_end(); return value;
;
; Small-C caller-clean x,y with A=READ or TEST. Result zero-extended in HL
; for the word APIs and in L for point. Preserve IX/IY. A temporary word
; holds the operation before the pixel call and the result before video_end.
bc__graphics_read_point:
        push af
        call _bc__graphics_begin
        pop bc
        jr z,@zero
        ld a,b
        BC_ABI_LOAD_SMALLC_PAIR
        ld c,a
        ld b,0
        call bc__graphics_pixel_regs
        push hl
        call _bc__video_end
        pop hl
        ld h,0
        ret
@zero:
        ld hl,0
        ret
