IFDEF BASECONF_VIDEO_TEXT_ZX_256
        MODULE bc__video_scroll_up_zx_text
SECTION code_clib
PUBLIC bc__video_scroll_up_zx_text
EXTERN _bc_video_page0_base
EXTERN zx__ink
EXTERN zx__paper
EXTERN zx__encode_attribute
EXTERN bc__video_scroll_up_zx
EXTERN zx__scroll_linear_plane

; Scrolls the standard ZX bitmap and attribute grid up one character row and
; clears the exposed row.
;
; C model:
;
;   scroll_zx_bitmap(8);
;   scroll_linear(page0_base+0x1800, 32, 24*32, zx_attribute(ink,paper));
;
; C = 8, active lease. This text-only adapter supplies the attribute behavior
; absent from scroll_up_pixels, even when that function receives rows==8.
; Preserve IX/IY; clobber AF/BC/DE/HL. No primitive-mode backend is required.
bc__video_scroll_up_zx_text:
        call bc__video_scroll_up_zx
        ld a,(zx__ink)
        ld e,a
        ld a,(zx__paper)
        ld d,a
        call zx__encode_attribute
        ld hl,(_bc_video_page0_base)
        ld de,1800h
        add hl,de
        ld de,32
        ld bc,24*32
        jp zx__scroll_linear_plane
ENDIF
