IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_640
        MODULE bc__video_scroll_up_atm640
SECTION code_clib
PUBLIC bc__video_scroll_up_atm640
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base
EXTERN zx__ink
EXTERN zx__paper
EXTERN bc__video_packed_pixels_regs
EXTERN bc__video_scroll_up_linear_planes

; Scrolls the ATM640 bitmap and attribute planes up together and initializes
; the exposed rows with the current colors.
;
; C model:
;
;   attr = encode_atm_attribute(ink,paper);
;   scroll_two_linear_planes(page1_base, rows, 0);
;   scroll_two_linear_planes(page0_base, rows, attr);
;
; C = rows, active lease. Preserve IX/IY; clobber AF/BC/DE/HL.
; Save the attribute/rows across bitmap copying; neither input API is needed.
bc__video_scroll_up_atm640:
        ld a,(zx__ink)
        ld e,a
        ld a,(zx__paper)
        ld d,a
        call bc__video_packed_pixels_regs
        push af
        push bc
        xor a
        ld hl,(_bc_video_page1_base)
        call bc__video_scroll_up_linear_planes
        pop bc
        pop af
        ld hl,(_bc_video_page0_base)
        jp bc__video_scroll_up_linear_planes
ENDIF
