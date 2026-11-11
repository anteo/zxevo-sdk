        MODULE zx__scroll_zx_plane
INCLUDE "video/z80/zx__scroll_zx.inc"
SECTION code_clib
PUBLIC zx__scroll_zx_plane
EXTERN zx__bitmap_offset
EXTERN zx__fill_bytes

; Scrolls one plane up in ZX scanline order and fills the vacated scanlines
; with the supplied byte.
;
; C model:
;
;   n = min(rows, 192);
;   for (y=0; y<192-n; ++y)
;       memcpy(base + zx__offset(y), base + zx__offset(y+n), 32);
;   for (; y<192; ++y) memset(base + zx__offset(y), blank, 32);
;
; HL = CPU plane origin, C = rows (zero is a no-op), A = blank.
; Requires an active lease and a writable 6144-byte ZX-layout plane; preserve
; IX/IY, clobber AF/BC/DE/HL. Six persistent local bytes (zx__scroll_zx.inc).
; Logical rows ascend even though physical offsets are non-linear: every source
; row is above the destination in logical y, and cannot have been overwritten.
zx__scroll_zx_plane:
        ld b,a
        ld a,c
        or a
        ret z
        cp 193
        jr c,@rows_ready
        ld c,192
@rows_ready:
        push ix
        ld ix,0
        add ix,sp
        push hl                      ; BASE -2/-1
        push bc                      ; ROWS -4, BLANK -3
        push de                      ; COPY_ROWS -6, Y -5
        xor a
        ld (ix+ZX_SCROLL_UP_Y),a
        ld a,192
        sub c
        ld (ix+ZX_SCROLL_UP_COPY_ROWS),a
        jr z,@fill
@copy:
        call @destination
        push hl
        ld a,(ix+ZX_SCROLL_UP_Y)
        add a,(ix+ZX_SCROLL_UP_ROWS)
        ld c,a
        ld de,0
        call zx__bitmap_offset
        ld e,(ix+ZX_SCROLL_UP_BASE)
        ld d,(ix+ZX_SCROLL_UP_BASE+1)
        add hl,de
        pop de
        ld bc,32
        ldir
        inc (ix+ZX_SCROLL_UP_Y)
        ld a,(ix+ZX_SCROLL_UP_COPY_ROWS)
        cp (ix+ZX_SCROLL_UP_Y)
        jr nz,@copy
@fill:
        call @destination
        ld a,(ix+ZX_SCROLL_UP_BLANK)
        ld bc,32
        call zx__fill_bytes
        inc (ix+ZX_SCROLL_UP_Y)
        ld a,(ix+ZX_SCROLL_UP_Y)
        cp 192
        jr nz,@fill
        ld sp,ix
        pop ix
        ret

; Resolves the CPU address of a ZX scanline for the scroll copy or fill.
;
; C model:
;
; return base + zx__offset(y);
;
; Preserve IX/IY; clobber AF/BC/DE/HL.
@destination:
        ld c,(ix+ZX_SCROLL_UP_Y)
        ld de,0
        call zx__bitmap_offset
        ld e,(ix+ZX_SCROLL_UP_BASE)
        ld d,(ix+ZX_SCROLL_UP_BASE+1)
        add hl,de
        ret
