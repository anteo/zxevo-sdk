IFDEF BASECONF_VIDEO_MODE_ENABLED_ZX_256
        MODULE bc__video_scroll_up_zx
SECTION code_clib
PUBLIC bc__video_scroll_up_zx
EXTERN _bc_video_page0_base
EXTERN zx__scroll_zx_plane

; Scrolls the standard ZX bitmap up without moving its character-cell
; attributes.
;
; C model:
;
; scroll_zx(page0_base, rows, 0); // attributes are unchanged
;
; C = rows, active lease. Preserve IX/IY; clobber AF/BC/DE/HL.
bc__video_scroll_up_zx:
        xor a
        ld hl,(_bc_video_page0_base)
        jp zx__scroll_zx_plane
ENDIF
