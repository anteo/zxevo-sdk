        MODULE zx__blit4_span
INCLUDE "graphics/z80/blit4.inc"
IFDEF TSCONF_VIDEO_16C
EXTERN ts_packed_address16
ENDIF
SECTION code_graphics
PUBLIC zx__blit4_span

; Copy one clipped row, retaining the neighbour of an odd edge or keyed pixel.
;
; address=map16c(x,y);
; for each source pixel {
;     color=next_nibble();
;     if (color!=key) replace_nibble(address,x&1,color);
;     if (++x is even) ++address;
; }
;
; IX=common frame. HL=destination, DE=source inside the loop; AF/BC volatile,
; IX/IY preserved. One row fits in its 256-byte stride; only its initial
; address resolution can change Page3. No DMA ownership is needed.
zx__blit4_span:
IFDEF TSCONF_VIDEO_16C
        ld l,(ix+BLIT_X)
        ld h,(ix+BLIT_X+1)
        ld a,l
        and 1
        ld (ix+BLIT_DEST_PHASE),a
        ld e,(ix+BLIT_Y)
        ld d,(ix+BLIT_Y+1)
        call ts_packed_address16
        ld a,(ix+BLIT_HALF)
        ld (ix+BLIT_SRC_HALF),a
        ld c,(ix+BLIT_WIDTH)
        ld b,(ix+BLIT_WIDTH+1)
        ld (ix+BLIT_COUNT),c
        ld (ix+BLIT_COUNT+1),b
        ld e,(ix+BLIT_SRC)
        ld d,(ix+BLIT_SRC+1)
@pixel:
        ld a,(de)
        bit 0,(ix+BLIT_SRC_HALF)
        jr nz,@source_low
        set 0,(ix+BLIT_SRC_HALF)
        rrca
        rrca
        rrca
        rrca
        jr @source_ready
@source_low:
        res 0,(ix+BLIT_SRC_HALF)
        inc de
@source_ready:
        and 15
        cp (ix+BLIT_KEY)
        jr z,@advance
        bit 0,(ix+BLIT_DEST_PHASE)
        jr nz,@right
        rlca
        rlca
        rlca
        rlca
        ld b,a
        ld a,(hl)
        and 00fh
        or b
        ld (hl),a
        jr @advance
@right:
        ld b,a
        ld a,(hl)
        and 0f0h
        or b
        ld (hl),a
@advance:
        ld a,(ix+BLIT_DEST_PHASE)
        xor 1
        ld (ix+BLIT_DEST_PHASE),a
        jr nz,@count
        inc hl
@count:
        ld c,(ix+BLIT_COUNT)
        ld b,(ix+BLIT_COUNT+1)
        dec bc
        ld (ix+BLIT_COUNT),c
        ld (ix+BLIT_COUNT+1),b
        ld a,b
        or c
        jr nz,@pixel
ENDIF
        ret
