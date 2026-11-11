IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_320
        MODULE bc__video_scroll_up_atm320
SECTION code_clib
PUBLIC bc__video_scroll_up_atm320
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base
EXTERN zx__paper
EXTERN bc__video_packed_pixels_regs
EXTERN bc__video_scroll_up_linear_planes

; Scrolls the ATM320 packed surface up by the requested scanlines and fills
; the exposed rows with paper color.
;
; C model:
;
; for each page in {page0,page1}, scroll its two 40-byte-row planes;
; all exposed pairs = pack(paper,paper).
;
; C = rows, active lease. Preserve IX/IY; clobber AF/BC/DE/HL.
; This object depends only on linear-plane kernels, not ZX addressing.
bc__video_scroll_up_atm320:
        ld a,(zx__paper)
        ld e,a
        ld d,a
        call bc__video_packed_pixels_regs
        push af
        push bc
        ld hl,(_bc_video_page0_base)
        call bc__video_scroll_up_linear_planes
        pop bc
        pop af
        ld hl,(_bc_video_page1_base)
        jp bc__video_scroll_up_linear_planes
ENDIF
