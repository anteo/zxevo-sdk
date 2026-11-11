IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_BITMAP
        MODULE bc__video_scroll_horizontal_zx
INCLUDE "video/scroll_horizontal.inc"
SECTION code_clib
PUBLIC bc__video_scroll_horizontal_zx
EXTERN _bc_video_page0_base
EXTERN zx__ink
EXTERN zx__paper
EXTERN zx__bitmap_offset
EXTERN zx__encode_attribute
EXTERN bc__video_shift_byte_row
EXTERN bc__video_scroll_horizontal_return
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_256
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_MULTICOLOR
EXTERN _bc_video_draw_surface_state
ENDIF
ENDIF

; Shifts the ZX or Multicolor bitmap horizontally and moves attributes for
; whole-byte shifts.
;
; C model:
;
;   for (y=0; y<192; ++y) shift_bytes(base + zx__offset(y), 32, pixels, right, 0);
;   if (pixels == 8) {
;       if (multicolor) shift each of 192 ZX-layout attribute rows at +0x2000;
;       else            shift 24 contiguous 32-byte attribute rows at +0x1800;
;   }
;
; Two persistent locals: Y, BLANK. Subcell shifts preserve attributes.
; IX is the dispatcher frame, with packed arguments pixels/right at +4/+5.
; Preserve IX/IY on return; all row arguments are passed in registers.
bc__video_scroll_horizontal_zx:
        push bc
        xor a
        ld (ix+BC_SCROLL_Y),a
        ld (ix+BC_SCROLL_BLANK),a
@bitmap:
        call @origin
        ld b,32
        ld c,(ix+BC_SCROLL_PIXELS)
        call bc__video_shift_byte_row
        inc (ix+BC_SCROLL_Y)
        ld a,(ix+BC_SCROLL_Y)
        cp 192
        jr nz,@bitmap
        ld a,(ix+BC_SCROLL_PIXELS)
        cp 8
        jp nz,bc__video_scroll_horizontal_return
        ld a,(zx__ink)
        ld e,a
        ld a,(zx__paper)
        ld d,a
        call zx__encode_attribute
        ld (ix+BC_SCROLL_BLANK),a
        xor a
        ld (ix+BC_SCROLL_Y),a
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_MULTICOLOR
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_256
        ld a,(_bc_video_draw_surface_state)
        or a
        jr z,@zx_attributes
ENDIF
@multicolor_attributes:
        call @origin
        ld de,2000h
        add hl,de
        ld b,32
        ld c,8
        call bc__video_shift_byte_row
        inc (ix+BC_SCROLL_Y)
        ld a,(ix+BC_SCROLL_Y)
        cp 192
        jr nz,@multicolor_attributes
        jp bc__video_scroll_horizontal_return
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_256
@zx_attributes:
        ld l,(ix+BC_SCROLL_Y)
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl                    ; y*32
        ld de,1800h
        add hl,de
        ld de,(_bc_video_page0_base)
        add hl,de
        ld b,32
        ld c,8
        call bc__video_shift_byte_row
        inc (ix+BC_SCROLL_Y)
        ld a,(ix+BC_SCROLL_Y)
        cp 24
        jr nz,@zx_attributes
        jp bc__video_scroll_horizontal_return
ENDIF

; Return HL = page0 CPU row origin; clobber AF/BC/DE.
@origin:
        ld c,(ix+BC_SCROLL_Y)
        ld de,0
        call zx__bitmap_offset
        ld de,(_bc_video_page0_base)
        add hl,de
        ret
ENDIF
