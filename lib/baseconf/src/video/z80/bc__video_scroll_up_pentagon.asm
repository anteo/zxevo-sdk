IFDEF BASECONF_VIDEO_MODE_ENABLED_PENTAGON_256
        MODULE bc__video_scroll_up_pentagon
SECTION code_clib
PUBLIC bc__video_scroll_up_pentagon
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base
EXTERN zx__paper
EXTERN bc__video_packed_pixels_regs
EXTERN bc__video_scroll_up_zx_planes

; Scrolls the Pentagon packed surface up using ZX scanline order and fills
; the exposed rows with paper color.
;
; C model:
;
; for each page in {page0,page1}, scroll its two ZX-layout planes;
; all exposed pairs = pack(paper,paper).
;
; C = rows, active lease. Preserve IX/IY; clobber AF/BC/DE/HL.
; Keeping this adapter in its own object avoids linking ATM row geometry.
bc__video_scroll_up_pentagon:
        ld a,(zx__paper)
        ld e,a
        ld d,a
        call bc__video_packed_pixels_regs
        push af
        push bc
        ld hl,(_bc_video_page0_base)
        call bc__video_scroll_up_zx_planes
        pop bc
        pop af
        ld hl,(_bc_video_page1_base)
        jp bc__video_scroll_up_zx_planes
ENDIF
