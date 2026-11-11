        MODULE zx__ellipse_walk
INCLUDE "graphics/z80/zx__ellipse.inc"
SECTION code_graphics
PUBLIC zx__ellipse_walk
PUBLIC zx__ellipse_endpoints
EXTERN l_mulu_32_16x16
EXTERN l_mulu_32_32x32

; Walk an axis-aligned ellipse using signed 32-bit midpoint errors.
;
; dx = (1-2*rx)*ry*ry; dy = rx*rx; err = dx+dy;
; dx_step = 2*ry*ry; dy_step = 2*rx*rx;
; bottom = y1; y0 = y1 = cy;
; do {
;     plot_corners(x0,x1,y0,y1); e2 = 2*err;
;     if (e2 <= dy) { ++y0; --y1; dy += dy_step; err += dy; }
;     if (e2 >= dx || 2*err > dy) { ++x0; --x1; dx += dx_step; err += dx; }
; } while (x0 <= x1);
; while (y0 < bottom) { plot_corners(x0-1,x1+1,y0,y1); ++y0; --y1; }
;
; IX points at the 34-byte frame in zx__ellipse.inc, with the precomputed
; endpoint pairs and original caller arguments. Radii are nonzero. IY is
; the pixel writer (HL=x, DE=y) and the caller owns the drawing surface.
; Error terms and their doubles must fit signed 32 bits. Preserve IX/IY;
; clobber AF/BC/DE/HL and shadow BC/DE/HL.
zx__ellipse_walk:
        ZX_ELLIPSE_LOAD_HL ZX_ELLIPSE_RX
        ld d,h
        ld e,l
        call l_mulu_32_16x16
        ZX_ELLIPSE_STORE_LONG ZX_ELLIPSE_DY
        add hl,hl
        rl e
        rl d
        ZX_ELLIPSE_STORE_LONG ZX_ELLIPSE_DY_STEP

        ZX_ELLIPSE_LOAD_HL ZX_ELLIPSE_RY
        ld d,h
        ld e,l
        call l_mulu_32_16x16
        push de
        push hl                       ; preserve ry squared for dx
        add hl,hl
        rl e
        rl d
        ZX_ELLIPSE_STORE_LONG ZX_ELLIPSE_DX_STEP

        ld c,(ix+ZX_ELLIPSE_RX)
        ld b,(ix+ZX_ELLIPSE_RX+1)
        ld hl,1
        or a
        sbc hl,bc
        or a
        sbc hl,bc
        ld de,-1                      ; high word of 1-2*rx for rx > 0
        exx
        pop hl
        pop de
        push ix                       ; native 32-bit multiply may use IX
        call l_mulu_32_32x32          ; low product bits work for either sign
        pop ix
        ZX_ELLIPSE_STORE_LONG ZX_ELLIPSE_DX
        ZX_ELLIPSE_STORE_LONG ZX_ELLIPSE_ERR
        ld de,ZX_ELLIPSE_ERR*256+ZX_ELLIPSE_DY
        call ellipse_add_long

        ZX_ELLIPSE_LOAD_HL ZX_ELLIPSE_Y1
        ZX_ELLIPSE_STORE_HL ZX_ELLIPSE_BOTTOM
        ZX_ELLIPSE_LOAD_HL ZX_ELLIPSE_CY
        ZX_ELLIPSE_STORE_HL ZX_ELLIPSE_Y0
        ZX_ELLIPSE_STORE_HL ZX_ELLIPSE_Y1

ellipse_step:
        call ellipse_plot
        call ellipse_double_error
        ld de,ZX_ELLIPSE_DY*256+ZX_ELLIPSE_E2
        call ellipse_less_long
        jr c,ellipse_check_x       ; dy < old 2*err
        ld a,ZX_ELLIPSE_Y0
        call ellipse_move_pair
        ld de,ZX_ELLIPSE_DY*256+ZX_ELLIPSE_DY_STEP
        call ellipse_add_long
        ld de,ZX_ELLIPSE_ERR*256+ZX_ELLIPSE_DY
        call ellipse_add_long

ellipse_check_x:
        ld de,ZX_ELLIPSE_E2*256+ZX_ELLIPSE_DX
        call ellipse_less_long
        jr nc,ellipse_step_x       ; old 2*err >= dx
        call ellipse_double_error ; original e2 is no longer needed
        ld de,ZX_ELLIPSE_DY*256+ZX_ELLIPSE_E2
        call ellipse_less_long
        jr nc,ellipse_check_end    ; dy >= updated 2*err
ellipse_step_x:
        ld a,ZX_ELLIPSE_X0
        call ellipse_move_pair
        ld de,ZX_ELLIPSE_DX*256+ZX_ELLIPSE_DX_STEP
        call ellipse_add_long
        ld de,ZX_ELLIPSE_ERR*256+ZX_ELLIPSE_DX
        call ellipse_add_long
ellipse_check_end:
        ZX_ELLIPSE_LOAD_HL ZX_ELLIPSE_X1
        ZX_ELLIPSE_LOAD_DE ZX_ELLIPSE_X0
        call ellipse_less_word
        jr nc,ellipse_step

        ; The finishing pass uses the last X pair before the two sides crossed.
        ZX_ELLIPSE_LOAD_HL ZX_ELLIPSE_X0
        dec hl
        ZX_ELLIPSE_STORE_HL ZX_ELLIPSE_X0
        ZX_ELLIPSE_LOAD_HL ZX_ELLIPSE_X1
        inc hl
        ZX_ELLIPSE_STORE_HL ZX_ELLIPSE_X1
ellipse_finish:
        ZX_ELLIPSE_LOAD_HL ZX_ELLIPSE_Y0
        ZX_ELLIPSE_LOAD_DE ZX_ELLIPSE_BOTTOM
        call ellipse_less_word
        jr nc,ellipse_done
        call ellipse_plot
        ld a,ZX_ELLIPSE_Y0
        call ellipse_move_pair
        jr ellipse_finish

ellipse_done:
        ret

; HL=center, DE=radius -> HL=center-radius, DE=center+radius. Preserve BC.
zx__ellipse_endpoints:
        or a
        sbc hl,de
        push hl
        add hl,de
        add hl,de
        ex de,hl
        pop hl
        ret

; Emit the four corners in row order. Keep coincident writes for XOR.
;
; plot_pair(y0); plot_pair(y1);
; plot_pair(y) { writer(x0,y); writer(x1,y); }
;
; The video lease is active. IX is the ellipse frame and IY is the native
; writer. Both survive each pixel call. Save Y across the first pixel of
; each row. The second pixel returns directly to the pair's caller.
ellipse_plot:
        ZX_ELLIPSE_LOAD_DE ZX_ELLIPSE_Y0
        call ellipse_plot_pair
        ZX_ELLIPSE_LOAD_DE ZX_ELLIPSE_Y1
ellipse_plot_pair:
        push de
        ZX_ELLIPSE_LOAD_HL ZX_ELLIPSE_X0
        call ellipse_plot_pixel
        pop de
        ZX_ELLIPSE_LOAD_HL ZX_ELLIPSE_X1
ellipse_plot_pixel:
        jp (iy)

; Advance a pair of adjacent words toward each other.
;
; ++pair[0]; --pair[1];
;
; A is the pair's frame offset. Preserve IX/IY, clobber AF/DE/HL.
ellipse_move_pair:
        ld e,a
        ld d,0
        push ix
        pop hl
        add hl,de
        inc (hl)
        jr nz,ellipse_move_last
        inc hl
        inc (hl)
        dec hl
ellipse_move_last:
        inc hl
        inc hl
        ld a,(hl)
        sub 1
        ld (hl),a
        ret nc
        inc hl
        dec (hl)
        ret

; Resolve frame offsets D,E to pointers DE,HL respectively. Preserve IX/IY.
ellipse_pair:
        push ix
        pop hl
        ld b,0
        ld c,d
        add hl,bc
        push hl
        push ix
        pop hl
        ld c,e
        add hl,bc
        pop de
        ret

; Add a four-byte error term to another, least significant byte first.
;
; frame_long[D] += frame_long[E];
;
; D and E are byte offsets. Clobber AF/BC/DE/HL, preserve IX/IY.
ellipse_add_long:
        call ellipse_pair
        ld b,4
        xor a
ellipse_add_byte:
        ld a,(de)
        adc a,(hl)
        ld (de),a
        inc de
        inc hl
        djnz ellipse_add_byte
        ret

; Store twice the current error in the comparison scratch word pair.
;
; e2 = 2*err;
;
; IX points at the ellipse frame. Clobber AF/BC/DE/HL, preserve IX/IY.
ellipse_double_error:
        ld de,ZX_ELLIPSE_E2*256+ZX_ELLIPSE_ERR
        call ellipse_pair
        ld b,4
        xor a
ellipse_shift_byte:
        ld a,(hl)
        rla
        ld (de),a
        inc hl
        inc de
        djnz ellipse_shift_byte
        ret

; Compare signed frame longs by subtracting with borrow through all bytes.
;
; return frame_long[D] < frame_long[E];
;
; D and E are byte offsets. Carry is the result. The final SBC supplies
; the sign and signed overflow of the full difference. Preserve IX/IY.
ellipse_less_long:
        call ellipse_pair
        ld b,4
        xor a
ellipse_compare_byte:
        ld a,(de)
        sbc a,(hl)
        inc de
        inc hl
        djnz ellipse_compare_byte
        jr ellipse_sign

; Compare signed HL and DE. Return carry for HL < DE, clobber AF/HL.
ellipse_less_word:
        or a
        sbc hl,de
        ld a,h
ellipse_sign:
        jp po,ellipse_sign_ready
        cpl                           ; sign XOR overflow
ellipse_sign_ready:
        rlca
        ret
