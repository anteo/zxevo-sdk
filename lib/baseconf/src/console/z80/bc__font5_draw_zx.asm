IFDEF BASECONF_VIDEO_TEXT_ZX_BITMAP
        MODULE bc__font5_draw_zx

SECTION code_clib
PUBLIC bc__font5_draw_zx
EXTERN bc__font5_draw_return
EXTERN bc__font5_bitmap_init
EXTERN bc__font5_bitmap_masks
EXTERN bc__font5_bitmap_row
EXTERN zx__bitmap_offset
EXTERN zx__attribute_address
EXTERN zx__draw_font5_cell
EXTERN zx__font_overlay_rows
EXTERN zx__encode_attribute
EXTERN _bc_video_page0_base

; Tail entry from the dispatcher: IX is the callback frame, SP=IX-5,
; glyph/width/height/background are initialized. Preserve IX/IY on final return.
;
; Draws a glyph at a pixel position on the ZX screen and colors the character
; cells it touches.
;
; Model:
;
; initial_bitmap=page0_base+zx__offset(y,x>>3); bitmap=initial_bitmap;
; if (width==5 && height==8 && opaque && !(x&1) && !(y&7)) return draw_5x8_cell();
; for each glyph row merge bits and advance the ZX raster address;
; if (opaque) write the attribute at each touched cell;
;
; Active lease, in-bounds glyph and dispatcher/bitmap contexts are required.
; The lease supplies the aligned page0 base. Page selection stays unchanged.
; AF/BC/DE/HL volatile; shared epilogue restores IX/IY. ZX raster stepping
; first increments H, then fixes the character-row/third boundary on wrap.
; This backend keeps the initial CPU address at IX-10/-9 for attributes.
bc__font5_draw_zx:
        ld hl,-13
        add hl,sp
        ld sp,hl                     ; eighteen bitmap-context bytes
        ld e,(ix+11)
        ld d,(ix+12)
        call zx__encode_attribute
        call bc__font5_bitmap_init
        ld a,(ix+4)                  ; an in-bounds ZX x fits in one byte
        rrca
        rrca
        rrca
        and 1Fh
        ld e,a
        ld d,0
        ld c,(ix+6)
        call zx__bitmap_offset
        ld de,(_bc_video_page0_base)
        add hl,de
        ld (ix-10),l
        ld (ix-9),h
        ld (ix-8),l
        ld (ix-7),h

        ld a,(ix-3)
        cp 5
        jr nz,@generic
        ld a,(ix-4)
        cp 8
        jr nz,@generic
        bit 0,(ix-5)
        jr nz,@generic
        ld a,(ix-6)
        and 1
        jr nz,@generic
        ld a,(ix+6)
        and 7
        jr nz,@generic
        ld l,(ix-2)
        ld h,(ix-1)
        ld e,(ix-8)
        ld d,(ix-7)
        ld a,(ix-6)
        ld c,(ix-18)
        call zx__draw_font5_cell
        jp bc__font5_draw_return
@generic:
        ld bc,1                      ; adjacent bitmap byte for a spilled glyph
        ld (ix-12),c
        ld (ix-11),b
        call bc__font5_bitmap_masks
        bit 0,(ix-5)
        jr z,@raster
        ld a,(ix-4)
        cp 8
        jr nz,@raster
        ld a,(ix+6)
        and 7
        jr nz,@raster
        ld l,(ix-2)
        ld h,(ix-1)
        ld e,(ix-8)
        ld d,(ix-7)
        ld a,(ix-6)
        ld c,(ix-13)
        call zx__font_overlay_rows
        jp bc__font5_draw_return
@raster:
        ld a,(ix-4)
        ld (ix-17),a
@row:
        call bc__font5_bitmap_row
        dec (ix-17)
        jr z,@attributes
        ld l,(ix-8)
        ld h,(ix-7)
        call @next_row
        ld (ix-8),l
        ld (ix-7),h
        jr @row
@attributes:
        bit 0,(ix-5)
        jp nz,bc__font5_draw_return
        ld l,(ix-10)
        ld h,(ix-9)
        call zx__attribute_address
        ex de,hl
        ld a,(ix-16)
        cp 9
        ld a,(ix-18)
        ld (hl),a
        jp c,bc__font5_draw_return
        inc hl
        ld (hl),a
        jp bc__font5_draw_return

@next_row:
        inc h
        ld a,h
        and 7
        ret nz
        ld a,l
        add a,32
        ld l,a
        jr nc,@same_third
        res 5,h
        ret
@same_third:
        ld a,h
        sub 8
        ld h,a
        ret

IFDEF BASECONF_VIDEO_TEXT_ZX_MULTICOLOR
PUBLIC bc__font5_draw_multicolor
EXTERN bc__font5_draw_pixels
; Multicolor retains the shared pixel fallback. An alias emits no jump/code.
defc bc__font5_draw_multicolor = bc__font5_draw_pixels
ENDIF
ENDIF
