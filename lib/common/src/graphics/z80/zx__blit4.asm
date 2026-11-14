        MODULE zx__blit4
INCLUDE "graphics/z80/blit4.inc"
SECTION code_graphics
PUBLIC zx__blit4
EXTERN zx__blit4_begin
EXTERN zx__blit4_span
EXTERN zx__blit4_end

; Validate and clip a linear 4bpp image, then send complete visible rows to
; the selected platform backend. Source, stack and code remain resident.
;
; Model:
;
; image = *source;
; if (empty(image)) return OK;
; require(pixels && stride >= ceil(width/2) && !address_wrap(image));
; begin(); clip(x,width,screen_width); clip(y,height,screen_height);
; pixels += skipped_rows*stride + skipped_pixels/2;
; first_half = skipped_pixels&1;
; while (height--) { span(pixels,x,y,width,first_half,key); pixels+=stride; ++y; }
; return end();
;
; A=key (FFh for opaque), SDCC caller-clean descriptor/x/y at SP+2/+4/+6.
; Status in L. AF/BC/DE/HL volatile, IX/IY preserved. Private stack fields
; are defined in blit4.inc; no DATA/BSS or global drawing colors are used.
; Descriptor fields are copied before the platform can remap any page.
zx__blit4:
        push ix
        ld ix,0
        add ix,sp
        ld hl,-BLIT_FRAME_SIZE
        add hl,sp
        ld sp,hl
        ld (ix+BLIT_KEY),a
        ld l,(ix+4)
        ld h,(ix+5)
        ld a,h
        or l
        jp z,invalid
        ; Reject an eight-byte descriptor crossing the CPU address boundary.
        ld de,7
        add hl,de
        jp c,invalid
        or a
        sbc hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld (ix+BLIT_SRC),e
        ld (ix+BLIT_SRC+1),d
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld (ix+BLIT_WIDTH),e
        ld (ix+BLIT_WIDTH+1),d
        ld c,(hl)
        inc hl
        ld b,(hl)
        inc hl
        ld (ix+BLIT_HEIGHT),c
        ld (ix+BLIT_HEIGHT+1),b
        ld a,d
        or e
        jp z,empty
        ld a,b
        or c
        jp z,empty
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ld (ix+BLIT_STRIDE),l
        ld (ix+BLIT_STRIDE+1),h
        ; ceil(width/2), avoiding overflow for width=65535.
        srl d
        rr e
        jr nc,@even_width
        inc de
@even_width:
        or a
        sbc hl,de
        jp c,invalid
        push de                     ; packed row bytes
        ld e,(ix+BLIT_STRIDE)
        ld d,(ix+BLIT_STRIDE+1)
        dec bc                      ; source footprint spans height-1 strides
        call multiply
        pop de
        jp c,invalid
        add hl,de
        jp c,invalid
        ld e,(ix+BLIT_SRC)
        ld d,(ix+BLIT_SRC+1)
        ld a,d
        or e
        jp z,invalid
        add hl,de
        jp c,invalid                ; exclusive end must remain representable
        ld (ix+BLIT_SOURCE_END),l
        ld (ix+BLIT_SOURCE_END+1),h
        call zx__blit4_begin         ; L=status, BC/DE=surface width/height
        ld a,l
        or a
        jp nz,done
        ld (ix+BLIT_SCREEN_WIDTH),c
        ld (ix+BLIT_SCREEN_WIDTH+1),b
        ld (ix+BLIT_SCREEN_HEIGHT),e
        ld (ix+BLIT_SCREEN_HEIGHT+1),d
        ld l,(ix+6)
        ld h,(ix+7)
        ld c,(ix+BLIT_WIDTH)
        ld b,(ix+BLIT_WIDTH+1)
        ld e,(ix+BLIT_SCREEN_WIDTH)
        ld d,(ix+BLIT_SCREEN_WIDTH+1)
        call clip_axis
        jp c,close
        ld (ix+BLIT_X),l
        ld (ix+BLIT_X+1),h
        ld (ix+BLIT_WIDTH),c
        ld (ix+BLIT_WIDTH+1),b
        ld l,(ix+BLIT_AXIS_SKIP)
        ld h,(ix+BLIT_AXIS_SKIP+1)
        ld a,l
        and 1
        ld (ix+BLIT_HALF),a
        srl h
        rr l
        ld e,(ix+BLIT_SRC)
        ld d,(ix+BLIT_SRC+1)
        add hl,de
        ld (ix+BLIT_SRC),l
        ld (ix+BLIT_SRC+1),h
        ld l,(ix+8)
        ld h,(ix+9)
        ld c,(ix+BLIT_HEIGHT)
        ld b,(ix+BLIT_HEIGHT+1)
        ld e,(ix+BLIT_SCREEN_HEIGHT)
        ld d,(ix+BLIT_SCREEN_HEIGHT+1)
        call clip_axis
        jp c,close
        ld (ix+BLIT_Y),l
        ld (ix+BLIT_Y+1),h
        ld (ix+BLIT_HEIGHT),c
        ld (ix+BLIT_HEIGHT+1),b
        ld c,(ix+BLIT_AXIS_SKIP)
        ld b,(ix+BLIT_AXIS_SKIP+1)
        ld e,(ix+BLIT_STRIDE)
        ld d,(ix+BLIT_STRIDE+1)
        call multiply               ; validated footprint guarantees no overflow
        ld e,(ix+BLIT_SRC)
        ld d,(ix+BLIT_SRC+1)
        add hl,de
        ld (ix+BLIT_SRC),l
        ld (ix+BLIT_SRC+1),h
@row:
        call zx__blit4_span
        ld l,(ix+BLIT_SRC)
        ld h,(ix+BLIT_SRC+1)
        ld e,(ix+BLIT_STRIDE)
        ld d,(ix+BLIT_STRIDE+1)
        add hl,de
        ld (ix+BLIT_SRC),l
        ld (ix+BLIT_SRC+1),h
        inc (ix+BLIT_Y)
        jr nz,@next_height
        inc (ix+BLIT_Y+1)
@next_height:
        ld l,(ix+BLIT_HEIGHT)
        ld h,(ix+BLIT_HEIGHT+1)
        dec hl
        ld (ix+BLIT_HEIGHT),l
        ld (ix+BLIT_HEIGHT+1),h
        ld a,h
        or l
        jr nz,@row
close:
        call zx__blit4_end
        jr done
invalid:
        ld l,1
        jr done
empty:
        ld l,0
done:
        ld sp,ix
        pop ix
        ret

; Multiply unsigned stride by row count with overflow detection.
;
; result=0; while (count) { if (count&1) checked_add(result,stride);
;     count>>=1; if (count) checked_double(stride); } return result;
;
; DE=stride, BC=count -> HL=product, CF=overflow. IX/IY preserved.
multiply:
        ld hl,0
@mul:
        ld a,b
        or c
        ret z                       ; OR clears carry
        bit 0,c
        jr z,@shift
        add hl,de
        ret c
@shift:
        srl b
        rr c
        ld a,b
        or c
        ret z
        sla e
        rl d
        ret c
        jr @mul

; Clip one signed position and unsigned extent without endpoint overflow.
;
; skip=max(-position,0); if (skip>=count) return EMPTY;
; count-=skip; position=max(position,0);
; if (position>=limit) return EMPTY;
; count=min(count,limit-position);
;
; HL=position, BC=count, DE=limit. Returns HL/BC clipped, CF=empty and
; stores the source skip at BLIT_AXIS_SKIP. IX/IY preserved, DE/AF volatile.
clip_axis:
        xor a
        ld (ix+BLIT_AXIS_SKIP),a
        ld (ix+BLIT_AXIS_SKIP+1),a
        bit 7,h
        jr z,@positive
        push de
        xor a
        sub l
        ld e,a
        sbc a,a
        sub h
        ld d,a                      ; unsigned -position, including -32768
        ld (ix+BLIT_AXIS_SKIP),e
        ld (ix+BLIT_AXIS_SKIP+1),d
        ld h,b
        ld l,c
        or a
        sbc hl,de
        pop de
        jr c,@empty
        ld a,h
        or l
        jr z,@empty
        ld b,h
        ld c,l
        ld hl,0
@positive:
        push hl
        ex de,hl
        or a
        sbc hl,de                   ; limit-position
        jr c,@pop_empty
        ld a,h
        or l
        jr z,@pop_empty
        or a
        sbc hl,bc
        jr nc,@fits
        add hl,bc                   ; available extent
        ld b,h
        ld c,l
@fits:
        pop hl
        or a
        ret
@pop_empty:
        pop hl
@empty:
        scf
        ret
