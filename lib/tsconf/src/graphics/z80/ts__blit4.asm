        MODULE ts__blit4
INCLUDE "graphics/z80/blit4.inc"
SECTION code_graphics
PUBLIC zx__blit4_begin
PUBLIC zx__blit4_span
PUBLIC zx__blit4_end
IFDEF TSCONF_VIDEO_16C
EXTERN ts_draw_config
EXTERN _zx_graphics_begin
EXTERN _zx_graphics_end
EXTERN ts_packed_address16
ENDIF

; Hold the selected 16C surface and reject source memory in borrowed W3.
;
; if (!selected) return NOT_INITIALIZED;
; if (mode!=16C) return UNSUPPORTED;
; if (source_end>0xc000) return UNSAFE_CONTEXT;
; return graphics_begin(),512,512;
;
; IX=validated common frame; source_end is exclusive and did not wrap.
; L=status, BC/DE=bounds. AF/BC/DE/HL volatile, IX/IY preserved.
zx__blit4_begin:
IFDEF TSCONF_VIDEO_16C
        ld a,(ts_draw_config)
        cp 0ffh
        ld l,4
        ret z
        and 3
        cp 1
        jr nz,@unsupported
        ld a,(ix+BLIT_SOURCE_END+1)
        cp 0c0h
        jr c,@resident
        jr nz,@unsafe
        ld a,(ix+BLIT_SOURCE_END)
        or a
        jr nz,@unsafe
@resident:
        call _zx_graphics_begin
        ld bc,512
        ld de,512
        ret
@unsafe:
        ld l,6
        ret
@unsupported:
ENDIF
        ld l,5
        ret

; Restore W3 at the outermost group boundary. Status in L, IX/IY preserved.
zx__blit4_end:
IFDEF TSCONF_VIDEO_16C
        jp _zx_graphics_end
ELSE
        ld l,0
        ret
ENDIF

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
