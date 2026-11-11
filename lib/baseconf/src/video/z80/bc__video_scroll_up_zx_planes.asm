IFDEF BASECONF_VIDEO_MODE_ENABLED_PENTAGON_256
        MODULE bc__video_scroll_up_zx_planes
SECTION code_clib
PUBLIC bc__video_scroll_up_zx_planes
EXTERN zx__scroll_zx_plane

; Scrolls the two ZX-layout planes in one mapped page up and fills their
; exposed rows.
;
; C model:
;
; scroll_zx(base, rows, blank); scroll_zx(base+0x2000, rows, blank);
;
; HL = mapped page CPU base, C = rows, A = encoded paper pair.
; Preserve IX/IY; clobber AF/BC/DE/HL. Three saved words retain the second
; plane's arguments across the first call; no static scratch or row buffer.
bc__video_scroll_up_zx_planes:
        push af
        push bc
        push hl
        call zx__scroll_zx_plane
        pop hl
        ld de,2000h
        add hl,de
        pop bc
        pop af
        jp zx__scroll_zx_plane
ENDIF
