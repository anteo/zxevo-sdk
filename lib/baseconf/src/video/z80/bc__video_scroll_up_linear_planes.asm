IFDEF BASECONF_VIDEO_MODE_LINEAR
        MODULE bc__video_scroll_up_linear_planes
SECTION code_clib
PUBLIC bc__video_scroll_up_linear_planes
EXTERN bc__video_row_offset_40
EXTERN zx__scroll_linear_plane

; Scrolls both 40-byte-wide planes in one mapped page up and fills the
; exposed rows with the supplied byte.
;
; C model:
;
;   n = min(rows, 200);
;   scroll_plane(page_base,        n*40, 8000, blank);
;   scroll_plane(page_base+0x2000, n*40, 8000, blank);
;
; HL = mapped page CPU base, C = rows (nonzero), A = encoded blank.
; Preserve IX/IY; clobber AF/BC/DE/HL. Each 8 KiB plane contains 8000 active
; bytes; its unused 192-byte tail is left untouched. No C request/page selector.
bc__video_scroll_up_linear_planes:
        push hl
        push af
        ld a,c
        cp 201
        jr c,@rows_ready
        ld a,200
@rows_ready:
        call bc__video_row_offset_40
        ex de,hl
        pop af
        pop hl
        push af
        push de
        push hl
        ld bc,8000
        call zx__scroll_linear_plane
        pop hl
        ld bc,2000h
        add hl,bc
        pop de
        pop af
        ld bc,8000
        jp zx__scroll_linear_plane
ENDIF
