        MODULE multipoint
SECTION code_graphics
PUBLIC _multipoint
EXTERN _bc__graphics_begin
EXTERN bc__graphics_pixel_regs
EXTERN _bc__video_end

defc BC_MULTIPOINT_Y = 4
defc BC_MULTIPOINT_X = 6
defc BC_MULTIPOINT_LENGTH = 8
defc BC_MULTIPOINT_HV = 10
defc BC_MULTIPOINT_LEFT = -2
defc BC_MULTIPOINT_VERTICAL = -1
defc BC_MULTIPOINT_BITS = -4

; Collect up to sixteen pixel-test bits in scan order.
;
; if (length < 1 || length > 16 || !graphics_begin()) return 0;
; bits = 0;
; while (length--) { bits = (bits << 1) | test_clipped_pixel(x,y);
;                   if (hv) ++y; else ++x; }
; video_end(); return bits;
;
; Small-C caller-clean y, x, length, hv at SP+2,+4,+6,+8. Return HL.
; IX points at saved IX. Two local words hold remaining count/direction
; and the result. Save HL=x and DE=y across each pixel test. Preserve IX/IY,
; clobber AF/BC/DE/HL. Outside points contribute zero.
_multipoint:
        push ix
        ld ix,0
        add ix,sp
        ld a,(ix+BC_MULTIPOINT_LENGTH+1)
        or a
        jr nz,@zero
        ld a,(ix+BC_MULTIPOINT_LENGTH)
        dec a
        cp 16
        jr nc,@zero
        call _bc__graphics_begin
        jr z,@zero

        ld l,(ix+BC_MULTIPOINT_LENGTH)
        ld a,(ix+BC_MULTIPOINT_HV)
        or (ix+BC_MULTIPOINT_HV+1)
        ld h,a
        push hl
        ld hl,0
        push hl
        ld l,(ix+BC_MULTIPOINT_X)
        ld h,(ix+BC_MULTIPOINT_X+1)
        ld e,(ix+BC_MULTIPOINT_Y)
        ld d,(ix+BC_MULTIPOINT_Y+1)
@sample:
        push hl
        push de
        ld bc,5                      ; PIXEL_TEST, no color argument
        call bc__graphics_pixel_regs
        ld a,l
        rrca                         ; test returns 0 or 1
        rl (ix+BC_MULTIPOINT_BITS)
        rl (ix+BC_MULTIPOINT_BITS+1)
        pop de
        pop hl
        dec (ix+BC_MULTIPOINT_LEFT)
        jr z,@done
        ld a,(ix+BC_MULTIPOINT_VERTICAL)
        or a
        jr z,@right
        inc de
        jr @sample
@right:
        inc hl
        jr @sample
@done:
        call _bc__video_end
        pop hl
        pop bc
        pop ix
        ret
@zero:
        ld hl,0
        pop ix
        ret
