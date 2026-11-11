        MODULE zx__draw_font5_cell

SECTION code_clib
PUBLIC zx__draw_font5_cell
EXTERN zx__attribute_address

; Draw an opaque 5x8 glyph and write the attribute of each cell it touches.
;
; draw_rows(glyph, bitmap, shift);
; attr = zx__attribute_address(bitmap);
; attr[0] = color; if (shift >= 4) attr[1] = color;
;
; HL=glyph, DE=first bitmap byte in a mapped 16 KiB window, A=shift 0/2/4/6,
; C=ZX attribute. Glyph fits the bitmap and starts on an eight-scanline boundary.
; Save the start address, shift and color across the row writer. AF/BC/DE/HL
; volatile, IX/IY preserved.
zx__draw_font5_cell:
        push de
        ld b,a
        push bc
        call zx__draw_font5_rows
        pop bc
        pop hl
        call zx__attribute_address
        ex de,hl
        ld (hl),c
        ld a,b
        cp 4
        ret c
        inc hl
        ld (hl),c
        ret

; Register ABI: HL = glyph, DE = first bitmap byte, A = shift 0/2/4/6.
; Draw eight opaque 5-pixel rows, preserving neighbours and IX/IY.
; The caller guarantees y is aligned to eight scanlines. Lower glyph bits
; are ignored. Counted loops keep shifts 4/6 compact instead of unrolling.
;
; Draws eight rows of an opaque five-pixel glyph at an aligned ZX position
; while keeping adjacent pixels intact.
;
; Model:
;
; for (row=0; row<8; ++row) {
;     bits=(glyph[row]&0xf8); merge five opaque bits at shift 0/2/4/6;
;     bitmap+=0x100; /* y is aligned so all eight rows remain in one cell */
; }
;
; Only the active mapped bitmap page is touched; attributes belong to caller.
; AF/BC/DE/HL clobbered; IX/IY preserved. A spill byte is accessed only for
; shifts 4/6, with clear masks that preserve the adjacent glyph.
zx__draw_font5_rows:
        or a
        jr z,@shift0
        cp 2
        jr z,@shift2
        cp 4
        jr z,@shift4
        ld b,8
@shift6_loop:
        ld a,(hl)
        rlca
        rlca
        and 03h                     ; only the two leading glyph bits land here
        ld c,a
        ld a,(de)
        and 0FCh
        or c
        ld (de),a
        inc de
        ld a,(hl)
        and 0F8h
        add a,a
        add a,a
        ld c,a
        ld a,(de)
        and 1Fh
        or c
        ld (de),a
        dec de
        inc hl
        inc d
        djnz @shift6_loop
        ret
@shift4:
        ld b,8
@shift4_loop:
        ld a,(hl)
        rrca
        rrca
        rrca
        rrca
        and 0Fh                     ; only the four leading glyph bits land here
        ld c,a
        ld a,(de)
        and 0F0h
        or c
        ld (de),a
        inc de
        ld a,(hl)
        and 0F8h
        add a,a
        add a,a
        add a,a
        add a,a
        ld c,a
        ld a,(de)
        and 7Fh
        or c
        ld (de),a
        dec de
        inc hl
        inc d
        djnz @shift4_loop
        ret
@shift2:
        ld b,8
@shift2_loop:
        ld a,(hl)
        and 0F8h
        rrca
        rrca
        ld c,a
        ld a,(de)
        and 0C1h
        or c
        ld (de),a
        inc hl
        inc d
        djnz @shift2_loop
        ret
@shift0:
        ld b,8
@shift0_loop:
        ld a,(hl)
        and 0F8h
        ld c,a
        ld a,(de)
        and 07h
        or c
        ld (de),a
        inc hl
        inc d
        djnz @shift0_loop
        ret
