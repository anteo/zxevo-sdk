        MODULE bc__video_text_character_planes
INCLUDE "video/text_rows.inc"
EXTERN bc__video_text_planes_select
SECTION code_clib
PUBLIC bc__video_text_character_planes

; Resolve a text plane pair in the surface supplied by the caller. Model:
;
; if (characters)
;     page, even, odd = atm ? (page1, 0x01c0, 0x21c0) : (page0, 0x01c0, 0x11c0);
; else
;     page, even, odd = atm ? (page0, 0x21c0, 0x01c1) : (page0, 0x31c0, 0x21c1);
; if (select_page(page) != ZX_OK) return failure;
; return cpu_base + even, cpu_base + odd;
;
; IX addresses text_rows.inc arguments, with an active prepared lease.
; Return HL/DE = even/odd origins on Z. NZ indicates a selection failure.
; Preserve IX/IY, clobber AF/BC/DE/HL. One saved word keeps the even offset
; across the page selector. The odd attribute byte starts one byte later.
bc__video_text_character_planes:
        ld c,(ix+BC_TEXT_ROWS_PAGE0)
        ld a,(ix+BC_TEXT_ROWS_MODE)
        cp 5                         ; BC_VIDEO_ATM_TEXT_80
        ld de,11C0h
        jr nz,@characters
        ld c,(ix+BC_TEXT_ROWS_PAGE1)
        ld d,21h
@characters:
        ld hl,01C0h
        jp bc__video_text_planes_select
