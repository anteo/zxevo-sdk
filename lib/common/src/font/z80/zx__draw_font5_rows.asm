        MODULE zx__draw_font5_rows
SECTION code_clib
PUBLIC zx__draw_font5_rows

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
; shifts 4/6. Each mask selects glyph bits to replace in the destination.
zx__draw_font5_rows:
        ex de,hl                     ; DE=glyph, HL=bitmap for masked writes
        ld b,8
        or a
        jr z,@shift0
        cp 2
        jr z,@shift2
        cp 4
        jr z,@shift4
@shift6:
        ld a,(de)
        rlca
        rlca                         ; glyph bits 7..3 now occupy bits 1,0,7,6,5
        ld c,a
        xor (hl)
        and 03h
        xor (hl)                     ; old ^ ((old ^ rotated) & field)
        ld (hl),a
        inc l                        ; a spill fits in the same 32-byte raster row
        ld a,c
        xor (hl)
        and 0e0h
        xor (hl)
        ld (hl),a
        dec l
        inc de
        inc h
        djnz @shift6
        ret
@shift4:
        ld a,(de)
        rrca
        rrca
        rrca
        rrca                         ; low nibble here, bit 7 in the next byte
        ld c,a
        xor (hl)
        and 0fh
        xor (hl)
        ld (hl),a
        inc l
        ld a,c
        xor (hl)
        and 80h
        xor (hl)
        ld (hl),a
        dec l
        inc de
        inc h
        djnz @shift4
        ret
@shift2:
        ld a,(de)
        rrca
        rrca
        xor (hl)
        and 3eh
        xor (hl)
        ld (hl),a
        inc de
        inc h
        djnz @shift2
        ret
@shift0:
        ld a,(de)
        xor (hl)
        and 0f8h
        xor (hl)
        ld (hl),a
        inc de
        inc h
        djnz @shift0
        ret
