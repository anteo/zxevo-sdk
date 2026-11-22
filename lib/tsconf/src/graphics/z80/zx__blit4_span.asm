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
; if (opaque && (x&1)==source_half) {
;     merge a leading low nibble if needed; copy whole bytes; merge any trailing high nibble;
;     return;
; }
; for each source pixel {
;     color=next_nibble();
;     if (color!=key) replace_nibble(address,x&1,color);
;     if (++x is even) ++address;
; }
;
; IX=common frame. HL=destination, DE=source and BC=pixels in the general loop.
; The aligned copy swaps HL/DE for LDIR and saves the trailing-pixel flag on the stack.
; AF/BC/DE/HL volatile,
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
        ld c,(ix+BLIT_WIDTH)
        ld b,(ix+BLIT_WIDTH+1)
        ld e,(ix+BLIT_SRC)
        ld d,(ix+BLIT_SRC+1)
        ld a,(ix+BLIT_HALF)
        ld (ix+BLIT_SRC_HALF),a
        xor (ix+BLIT_DEST_PHASE)
        jr nz,@pixel
        bit 7,(ix+BLIT_KEY)         ; FFh denotes opaque
        jr z,@pixel

        bit 0,(ix+BLIT_HALF)
        jr z,@bytes
        ld a,(de)
        call @merge_low
        inc de
        inc hl
        dec bc
@bytes:
        ex de,hl                     ; HL=source, DE=destination
        srl b
        rr c
        push af                      ; carry = one trailing high nibble
        ld a,b
        or c
        jr z,@tail                   ; LDIR needs a nonzero byte count
        ldir
@tail:
        pop af
        ret nc
        ex de,hl
        ld a,(de)
        jr @merge_high

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
        call @merge_high
        jr @advance
@right:
        call @merge_low
@advance:
        ld a,(ix+BLIT_DEST_PHASE)
        xor 1
        ld (ix+BLIT_DEST_PHASE),a
        jr nz,@count
        inc hl
@count:
        dec bc
        ld a,b
        or c
        jr nz,@pixel
        ret

; Replace the selected field with the corresponding bits of A.
; old ^ ((old ^ new) & mask) keeps the neighbouring nibble.
@merge_high:
        xor (hl)
        and 0f0h
        jr @merge
@merge_low:
        xor (hl)
        and 0fh
@merge:
        xor (hl)
        ld (hl),a
ENDIF
        ret
